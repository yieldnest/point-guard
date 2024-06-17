// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {IAVSDirectory} from "@eigenlayer/contracts/interfaces/IAVSDirectory.sol";

import {BN254, IBLSSignatureChecker} from "@eigenlayer-middleware/src/interfaces/IBLSSignatureChecker.sol";

import {StakeRegistry, IDelegationManager, IStrategy} from "@eigenlayer-middleware/src/StakeRegistry.sol";
import {RegistryCoordinator, IPauserRegistry, IRegistryCoordinator} from "@eigenlayer-middleware/src/RegistryCoordinator.sol";
import {BLSApkRegistry} from "@eigenlayer-middleware/src/BLSApkRegistry.sol";
import {IndexRegistry} from "@eigenlayer-middleware/src/IndexRegistry.sol";

import {EmptyContract} from "@eigenlayer/test/mocks/EmptyContract.sol";

import {PointsGuardServiceManager, IRegistryCoordinator, IStakeRegistry} from "../src/PointsGuardServiceManager.sol";
import {PointsGuardTaskManager, IPointsGuardTaskManager} from "../src/PointsGuardTaskManager.sol";

import "forge-std/Script.sol";
import "forge-std/console.sol";

// ---- Usage ----

// deploy:
// forge script script/PointsGuardDemo.s.sol:PointsGuardDemo --slow --rpc-url http://anvil:8545 --broadcast

contract PointsGuardDemo is Script {

    // --------
    // TODO: update immutable variables below according to Anvil deployment
    uint256 public immutable deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 public immutable proxyOwnerPrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 public immutable ownerPrivateKey = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
    uint256 public immutable InitializerPrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
    address public immutable proxyOwner = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public immutable owner = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address public immutable user = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
    // --------

    address public emptyContract;

    PointsGuardTaskManager public taskManager;
    PointsGuardServiceManager public serviceManager;
    RegistryCoordinator public registryCoordinator;
    StakeRegistry public stakeRegistry;
    BLSApkRegistry public blsApkRegistry;
    IndexRegistry public indexRegistry;

    IAVSDirectory public constant avsDirectory = IAVSDirectory(0x135DDa560e946695d6f155dACaFC6f1F25C1F5AF);
    IDelegationManager public constant delegationManager = IDelegationManager(0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A);
    IStrategy public constant sfrxETHStrategy = IStrategy(0x8CA7A5d6f3acd3A7A8bC468a8CD0FB14B6BD28b6);
    IPauserRegistry public constant pauserRegistry = IPauserRegistry(0x0c431C66F4dE941d089625E5B423D00707977060);

    uint32 public taskCreatedBlock;
    uint256 public constant protocolId = 0;
    uint32 public constant quorumThresholdPercentage = 0;
    bytes public constant quorumNumbers = "0x1234";

    uint32 public constant TASK_RESPONSE_WINDOW_BLOCK = 30;

    // ============================================================================================
    // Run
    // ============================================================================================

    function run() public {

        _deployProxyContracts();

        _deployImplementationContractsAndInitialize();

        _registerProtocol();

        console.log("=====================================");
        console.log("=====================================");
        console.log("taskManager: ", address(taskManager));
        console.log("serviceManager: ", address(serviceManager));
        console.log("=====================================");
        console.log("Task created: ");
        console.log("protocolId: ", protocolId);
        console.log("user: ", user);
        console.log("taskCreatedBlock: ", taskCreatedBlock);
        console.log("quorumThresholdPercentage: ", quorumThresholdPercentage);
        console.log("quorumNumbers: 0x1234");
        console.log("=====================================");
        console.log("=====================================");
    }

    // ============================================================================================
    // Internal helpers
    // ============================================================================================

    function _deployProxyContracts() internal {
        vm.startBroadcast(deployerPrivateKey);

        // deploy empty contract
        emptyContract = address(new EmptyContract());

        // deploy proxy contracts
        taskManager = PointsGuardTaskManager(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        serviceManager = PointsGuardServiceManager(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        registryCoordinator = RegistryCoordinator(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        stakeRegistry = StakeRegistry(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        blsApkRegistry = BLSApkRegistry(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        indexRegistry = IndexRegistry(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));

        vm.stopBroadcast();
    }

    function _deployImplementationContractsAndInitialize() internal {
        vm.startBroadcast(proxyOwnerPrivateKey);

        // deploy implementation contracts and initialize

        // StakeRegistry
        address _stakeRegistryImplementation = address(new StakeRegistry(IRegistryCoordinator(registryCoordinator), IDelegationManager(delegationManager)));
        TransparentUpgradeableProxy(payable(address(stakeRegistry))).upgradeTo(_stakeRegistryImplementation);

        // BLSApkRegistry
        address _blsApkRegistryImplementation = address(new BLSApkRegistry(IRegistryCoordinator(registryCoordinator)));
        TransparentUpgradeableProxy(payable(address(blsApkRegistry))).upgradeTo(_blsApkRegistryImplementation);

        // IndexRegistry
        address _indexRegistryImplementation = address(new IndexRegistry(IRegistryCoordinator(registryCoordinator)));
        TransparentUpgradeableProxy(payable(address(indexRegistry))).upgradeTo(_indexRegistryImplementation);

        // RegistryCoordinator
        address _registryCoordinatorImplementation = address(new RegistryCoordinator(serviceManager, stakeRegistry, blsApkRegistry, indexRegistry));
        TransparentUpgradeableProxy(payable(address(registryCoordinator))).upgradeTo(_registryCoordinatorImplementation);

        // TaskManager
        address _taskManagerImplementation = address(new PointsGuardTaskManager(IRegistryCoordinator(registryCoordinator), TASK_RESPONSE_WINDOW_BLOCK));
        TransparentUpgradeableProxy(payable(address(taskManager))).upgradeTo(_taskManagerImplementation);

        // ServiceManager
        address _serviceManagerImplementation = address(new PointsGuardServiceManager(IAVSDirectory(avsDirectory), IRegistryCoordinator(registryCoordinator), IStakeRegistry(stakeRegistry), PointsGuardTaskManager(taskManager), owner));
        TransparentUpgradeableProxy(payable(address(serviceManager))).upgradeTo(_serviceManagerImplementation);

        vm.stopBroadcast();

        vm.startBroadcast(InitializerPrivateKey);

        // initialize contracts
        _initializeRegistryCoordinator();
        _initializeTaskManager();

        vm.stopBroadcast();
    }

    function _initializeRegistryCoordinator() internal {
        IRegistryCoordinator.OperatorSetParam[] memory _operatorSetParam = new IRegistryCoordinator.OperatorSetParam[](1);
        _operatorSetParam[0] = IRegistryCoordinator.OperatorSetParam({
            maxOperatorCount: 10,
            kickBIPsOfOperatorStake: 100,
            kickBIPsOfTotalStake: 100
        });

        uint96[] memory _minimumStakes = new uint96[](1);
        _minimumStakes[0] = 0;

        IStakeRegistry.StrategyParams[][] memory _strategyParams = new IStakeRegistry.StrategyParams[][](1);
        _strategyParams[0] = new IStakeRegistry.StrategyParams[](1);
        _strategyParams[0][0] = IStakeRegistry.StrategyParams({
            strategy: sfrxETHStrategy,
            multiplier: 1
        });

        registryCoordinator.initialize(
            owner, // _initialOwner
            owner, // _churnApprover
            owner, // _ejector
            pauserRegistry, // _pauserRegistry
            0, // _initialPausedStatus
            _operatorSetParam, // _operatorSetParams
            _minimumStakes, // _minimumStakes
            _strategyParams // _strategyParams
        );
    }

    function _initializeTaskManager() internal {
        taskManager.initialize(
            serviceManager, // _serviceManager
            pauserRegistry, // _pauserRegistry
            owner, // initialOwner
            owner, // _aggregator
            owner // _generator
        );
    }

    function _registerProtocol() internal {
        vm.startBroadcast(ownerPrivateKey);

        // register protocol
        string memory _pointsScriptReference = "GITHUB_URL";
        serviceManager.registerProtocol(_pointsScriptReference);

        vm.stopBroadcast();
    }

    function _createNewTask() public {

        taskCreatedBlock = uint32(block.number);

        IPointsGuardTaskManager.Task memory _task = IPointsGuardTaskManager.Task({
            protocolId: protocolId,
            user: user,
            taskCreatedBlock: taskCreatedBlock,
            quorumThresholdPercentage: quorumThresholdPercentage,
            quorumNumbers: quorumNumbers
        });

        vm.startBroadcast(ownerPrivateKey);

        taskManager.createNewTask(
            protocolId,
            user,
            quorumThresholdPercentage,
            quorumNumbers
        );

        vm.stopBroadcast();
    }
}