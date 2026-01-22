// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AIRProtocolCore
/// @notice On-chain truth ledger for AIR Protocol Phase 1 (Genesis Validator PoA).
contract AIRProtocolCore {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotValidator(); // Caller is not the genesis validator
    error ReportAlreadyCommitted(); // A report with this ID has already been committed
    error ZeroReportId(); // The provided report ID is zero
    error EmptyReportCid(); // The provided report CID is empty

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ReportCommitted(
        bytes32 indexed reportId,
        string reportCid,
        uint64 airScore,
        address indexed validator,
        uint64 blockTimestamp
    );

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Genesis validator address for Phase 1 (PoA).
    address public immutable genesisValidator;

    struct Report {
        string reportCid; // IPFS CID of the report data
        uint64 airScore; // e.g. 0–10000 (basis points)
        uint64 blockTimestamp; // when committed
        address validator; // who committed
    }

    // reportId => Report
    mapping(bytes32 => Report) private _reports;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _genesisValidator) {
        if (_genesisValidator == address(0)) revert NotValidator();
        genesisValidator = _genesisValidator;
    }

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyValidator() {
        if (msg.sender != genesisValidator) revert NotValidator();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                  VIEWS
    //////////////////////////////////////////////////////////////*/

    function getReport(bytes32 reportId)
        external
        view
        returns (Report memory)
    {
        return _reports[reportId];
    }

    function exists(bytes32 reportId) external view returns (bool) {
        return _reports[reportId].blockTimestamp != 0;
    }

    /*//////////////////////////////////////////////////////////////
                                  LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Commit a report's data to chain.
    /// @dev Called only by the Genesis Validator service in Phase 1.
    function commitReport(
        bytes32 reportId,
        string calldata reportCid,
        uint64 airScore
    ) external onlyValidator {
        if (reportId == bytes32(0)) revert ZeroReportId();
        if (_reports[reportId].blockTimestamp != 0) revert ReportAlreadyCommitted();
        if (bytes(reportCid).length == 0) revert EmptyReportCid();

        _reports[reportId] = Report({
            reportCid: reportCid,
            airScore: airScore,
            blockTimestamp: uint64(block.timestamp),
            validator: msg.sender
        });

        emit ReportCommitted(
            reportId,
            reportCid,
            airScore,
            msg.sender,
            uint64(block.timestamp)
        );
    }
}
