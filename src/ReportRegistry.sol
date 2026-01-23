// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IReportRegistry} from "./Interfaces/IReportRegistry.sol";
import {ERC2771Context, Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract ReportRegistry is IReportRegistry, Ownable, ERC2771Context {
    mapping(uint256 => Report) private _reports;
    mapping(string => bool) private _cidExists;
    uint256 private _reportCounter;

    constructor(address initialOwner, address trustedForwarder) 
        Ownable(initialOwner) 
        ERC2771Context(trustedForwarder) 
    {}

    function registerReport(string calldata cid) external onlyOwner {
        require(!_cidExists[cid], "CID already exists ");
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

    // FIX: Renamed parameters from (start, end) to (offset, limit) to match Interface
    function getReports(uint256 offset, uint256 limit) external view override returns (Report[] memory) {
        uint256 count = _reportCounter; 
        
        // Handle out of bounds or empty requests
        if (offset == 0 || offset > count) {
            return new Report[](0); 
        }

        // Calculate the end point based on limit
        uint256 end = offset + limit - 1; 
        if (end > count) {
            end = count; 
        }

        uint256 size = end - offset + 1; 
        Report[] memory reports = new Report[](size);
        uint256 j = 0; 
        
        for (uint256 i = offset; i <= end; i++) {
            reports[j] = _reports[i]; 
            j++; 
        }
        return reports; 
    }

    // Required overrides for ERC2771Context
    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view virtual override(Context, ERC2771Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}