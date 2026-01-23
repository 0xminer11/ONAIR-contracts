const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AIR Protocol Integration", function () {
  let AIR, airToken;
  let Treasury, treasury;
  let Emissions, emissions;
  let MerkleDistributor, distributor;
  let owner, user1, user2, forwarder;

  const INITIAL_WEEKLY_EMISSION = ethers.parseEther("100000");

  beforeEach(async function () {
    [owner, user1, user2, forwarder] = await ethers.getSigners();

    // 1. Deploy AIR Token
    AIR = await ethers.getContractFactory("AIRToken");
    airToken = await AIR.deploy(owner.address, forwarder.address); 

    // 2. Deploy TreasuryVault
    Treasury = await ethers.getContractFactory("TreasuryVault");
    treasury = await Treasury.deploy(await airToken.getAddress(), owner.address); 

    // 3. Deploy MerkleDistributor
    MerkleDistributor = await ethers.getContractFactory("MerkleDistributorEpoch");
    distributor = await MerkleDistributor.deploy(await airToken.getAddress(), owner.address); 

    // 4. Deploy EmissionsController
    Emissions = await ethers.getContractFactory("EmissionsController");
    emissions = await Emissions.deploy(
      await treasury.getAddress(),
      await distributor.getAddress(),
      INITIAL_WEEKLY_EMISSION,
      owner.address
    ); 

    // 5. Setup Permissions
    await treasury.setEmissionsController(await emissions.getAddress()); 
    
    // Seed Treasury with AIR tokens
    await airToken.transfer(await treasury.getAddress(), ethers.parseEther("1000000"));
  });

  describe("Treasury & Emissions Flow", function () {
    it("Should allow the owner to fund an epoch", async function () {
      const epochId = 1;
      
      // Execute funding
      await expect(emissions.fundEpoch(epochId))
        .to.emit(emissions, "EpochFunded")
        .withArgs(epochId, INITIAL_WEEKLY_EMISSION); 

      // Verify Treasury balance decreased and Distributor increased
      expect(await airToken.balanceOf(await distributor.getAddress()))
        .to.equal(INITIAL_WEEKLY_EMISSION);
    });

    it("Should revert if funding the same epoch twice", async function () {
      await emissions.fundEpoch(1);
      await expect(emissions.fundEpoch(1)).to.be.revertedWithCustomError(emissions, "AlreadyFunded"); 
    });

    it("Should only allow the emissions controller to pull from treasury", async function () {
      await expect(treasury.connect(user1).pullTo(user1.address, 100))
        .to.be.revertedWithCustomError(treasury, "NotAuthorized"); 
    });
  });

  describe("Merkle Distribution", function () {
    it("Should allow owner to set Merkle Root once", async function () {
      const root = ethers.keccak256(ethers.toUtf8Bytes("root1"));
      await distributor.setMerkleRoot(1, root); 
      
      expect(await distributor.merkleRoots(1)).to.equal(root); 
      
      await expect(distributor.setMerkleRoot(1, root))
        .to.be.revertedWithCustomError(distributor, "RootAlreadySet"); 
    });
  });

  describe("Staking Logic", function () {
    let Staking, staking;

    beforeEach(async function () {
      Staking = await ethers.getContractFactory("Staking");
      staking = await Staking.deploy(await airToken.getAddress()); 
      
      // Give user1 some tokens and approve staking contract
      await airToken.transfer(user1.address, ethers.parseEther("1000"));
      await airToken.connect(user1).approve(await staking.getAddress(), ethers.parseEther("1000"));
    });

    it("Should track eligibility based on minimum stake", async function () {
      const minStake = ethers.parseEther("500"); 
      
      await staking.connect(user1).stake(ethers.parseEther("400")); 
      expect(await staking.isEligible(user1.address)).to.equal(false); 

      await staking.connect(user1).stake(ethers.parseEther("100"));
      expect(await staking.isEligible(user1.address)).to.equal(true); 
    });

    it("Should allow unstaking and update total staked", async function () {
      const amount = ethers.parseEther("500");
      await staking.connect(user1).stake(amount);
      
      await staking.connect(user1).unstake(amount); 
      expect(await staking.totalStaked()).to.equal(0); 
    });
  });

  describe("Report Registry", function () {
    let Registry, registry;

    beforeEach(async function () {
      Registry = await ethers.getContractFactory("ReportRegistry");
      registry = await Registry.deploy(owner.address); 
    });

    it("Should register a report and prevent CID duplicates", async function () {
      const cid = "QmTest123";
      await registry.registerReport(cid); 
      
      expect(await registry.getReportCount()).to.equal(1);
      
      await expect(registry.registerReport(cid))
        .to.be.revertedWith("CID already exists"); 
    });
  });
});