// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IReportRegistry} from "./Interfaces/IReportRegistry.sol";

contract ReportRegistry is IReportRegistry, Ownable {
    mapping(uint256 => Report) private _reports;
    mapping(string => bool) private _cidExists;
    uint256 private _reportCounter;

    constructor(address initialOwner) Ownable(initialOwner) {

    }

    function registerReport(string calldata cid) external onlyOwner {
        require(!_cidExists[cid], "CID already exists");
        _reportCounter++;
        uint256 reportId = _reportCounter;
        _reports[reportId] = Report({
            reportId: reportId,
            cid: cid,
            timestamp: block.timestamp
        });
        _cidExists[cid] = true;
        emit ReportRegistered(reportId, cid, block.timestamp);
    }

    function getReportById(uint256 reportId) external view returns (Report memory) {
        return _reports[reportId];
    }

    function getReportCount() external view returns (uint256) {
        return _reportCounter;
    }
}
