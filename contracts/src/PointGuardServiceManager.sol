// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@eigenlayer/contracts/libraries/BytesLib.sol";
import "./IPointGuardTaskManager.sol";
import "./IPointGuardServiceManager.sol";
import "@eigenlayer-middleware/src/ServiceManagerBase.sol";

/**
 * @title Primary entrypoint for procuring services from PointGuard.
 * @author Layr Labs, Inc.
 */
contract PointGuardServiceManager is IPointGuardServiceManager, ServiceManagerBase {
    using BytesLib for bytes;

    uint256 public protocolId;

    mapping(uint256 => string) public pointsOperatorReferences;

    address public immutable registrationManager;

    IPointGuardTaskManager public immutable PointGuardTaskManager;

    /// @notice when applied to a function, ensures that the function is only callable by the `registryCoordinator`.
    modifier onlyPointGuardTaskManager() {
        require(
            msg.sender == address(PointGuardTaskManager),
            "onlyPointGuardTaskManager: not from point guard task manager"
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
        IPointGuardTaskManager _pointGuardTaskManager,
        address _registrationManager
    )
        ServiceManagerBase(
            _avsDirectory,
            IPaymentCoordinator(address(0)),
            _registryCoordinator,
            _stakeRegistry
        )
    {
        PointGuardTaskManager = _pointGuardTaskManager;
        registrationManager = _registrationManager;
    }

    /// @notice Registers a new protocol with PointGuard.
    /// @dev The operator reference should be reviewed by the PointGuard team/gov to ensure it is safe.
    /// @param pointsOperatorReference The `pointsOperatorReference` is a Github URL that points to the operator that
    ///                              PointGuard will use to calculate the amount of points.
    function registerProtocol(string memory pointsOperatorReference) external onlyRegistrationManager {
        pointsOperatorReferences[protocolId] = pointsOperatorReference;
        ++protocolId;
    }

    /// @notice Called in the event of challenge resolution, in order to forward a call to the Slasher, which 'freezes' the `operator`.
    /// @dev The Slasher contract is under active development and its interface expected to change.
    ///      We recommend writing slashing logic without integrating with the Slasher at this point in time.
    function freezeOperator(
        address operatorAddr
    ) external onlyPointGuardTaskManager {
        // slasher.freezeOperator(operatorAddr);
    }

    function isProtocolRegistered(uint256 _protocolId) external view returns (bool) {
        return bytes(pointsOperatorReferences[_protocolId]).length > 0;
    }
}
