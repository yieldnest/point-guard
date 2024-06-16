// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPointsGuardServiceManager {
    function isProtocolRegistered(uint256 _protocolId) external view returns (bool);
}