// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@eigenlayer/contracts/libraries/BytesLib.sol";
import "./IPointsGuardTaskManager.sol";
import "./IPointsGuardServiceManager.sol";
import "@eigenlayer-middleware/src/ServiceManagerBase.sol";

/**
 * @title Primary entrypoint for procuring services from PointsGuard.
 * @author Layr Labs, Inc.
 */
contract PointsGuardServiceManager is IPointsGuardServiceManager, ServiceManagerBase {
    using BytesLib for bytes;

    uint256 public protocolId;

    mapping(uint256 => string) public pointsScriptReferences;

    address public immutable registrationManager;

    IPointsGuardTaskManager public immutable pointsGuardTaskManager;

    /// @notice when applied to a function, ensures that the function is only callable by the `registryCoordinator`.
    modifier onlyPointsGuardTaskManager() {
        require(
            msg.sender == address(pointsGuardTaskManager),
            "onlyPointsGuardTaskManager: not from credible squaring task manager"
        );
        _;
    }

    modifier onlyRegistrationManager() {
        require(
            msg.sender == registrationManager,
            "onlyRegistrationManager: not from registration manager"
        );
        _;
    }

    constructor(
        IAVSDirectory _avsDirectory,
        IRegistryCoordinator _registryCoordinator,
        IStakeRegistry _stakeRegistry,
        IPointsGuardTaskManager _pointsGuardTaskManager,
        address _registrationManager
    )
        ServiceManagerBase(
            _avsDirectory,
            IPaymentCoordinator(address(0)), // inc-sq doesn't need to deal with payments
            _registryCoordinator,
            _stakeRegistry
        )
    {
        pointsGuardTaskManager = _pointsGuardTaskManager;
        registrationManager = _registrationManager;
    }

    /// @notice Registers a new protocol with PointsGuard.
    /// @dev The script reference should be reviewed by the PointsGuard team/gov to ensure it is safe.
    /// @param pointsScriptReference The `pointsScriptReference` is a Github URL that points to the script that
    ///                              PointsGuard will use to calculate the amount of points.
    function registerProtocol(string memory pointsScriptReference) external onlyRegistrationManager {
        pointsScriptReferences[protocolId] = pointsScriptReference;
        ++protocolId;
    }

    /// @notice Called in the event of challenge resolution, in order to forward a call to the Slasher, which 'freezes' the `operator`.
    /// @dev The Slasher contract is under active development and its interface expected to change.
    ///      We recommend writing slashing logic without integrating with the Slasher at this point in time.
    function freezeOperator(
        address operatorAddr
    ) external onlyPointsGuardTaskManager {
        // slasher.freezeOperator(operatorAddr);
    }

    function isProtocolRegistered(uint256 _protocolId) external view returns (bool) {
        return bytes(pointsScriptReferences[_protocolId]).length > 0;
    }
}
