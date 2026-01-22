// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IReportRegistry {
    struct Report {
        uint256 reportId;
        string cid;
        uint256 timestamp;
    }

    event ReportRegistered(
        uint256 indexed reportId,
        string cid,
        uint256 timestamp
    );

    function registerReport(string calldata cid) external;

    function getReportById(uint256 reportId) external view returns (Report memory);

    function getReportCount() external view returns (uint256);
}
