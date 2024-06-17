// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPointGuardServiceManager {
    function isProtocolRegistered(uint256 _protocolId) external view returns (bool);
}