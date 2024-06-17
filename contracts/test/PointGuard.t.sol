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

import {PointGuardServiceManager, IRegistryCoordinator, IStakeRegistry} from "../src/PointGuardServiceManager.sol";
import {PointGuardTaskManager, IPointGuardTaskManager} from "../src/PointGuardTaskManager.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract PointGuardTest is Test {

    event NewTaskCreated(uint32 indexed taskIndex, IPointGuardTaskManager.Task task);

    event TaskResponded(
        IPointGuardTaskManager.TaskResponse taskResponse,
        IPointGuardTaskManager.TaskResponseMetadata taskResponseMetadata
    );

    event TaskChallengedUnsuccessfully(
        uint32 indexed taskIndex,
        address indexed challenger
    );

    event TaskChallengedSuccessfully(
        uint32 indexed taskIndex,
        address indexed challenger
    );

    event TaskChallengeResolved(
        uint32 indexed referenceTaskIndex,
        bool isChallengeValid
    );

    uint256 public protocolId = 0;
    uint32 public quorumThresholdPercentage = 0;
    uint32 public taskCreatedBlock;
    bytes public quorumNumbers = "0x1234";

    address public aggregator;
    address public generator;
    address public proxyOwner;
    address public owner;
    address public user;

    address public emptyContract;

    PointGuardTaskManager public taskManager;
    PointGuardServiceManager public serviceManager;
    RegistryCoordinator public registryCoordinator;
    StakeRegistry public stakeRegistry;
    BLSApkRegistry public blsApkRegistry;
    IndexRegistry public indexRegistry;

    IAVSDirectory public constant avsDirectory = IAVSDirectory(0x135DDa560e946695d6f155dACaFC6f1F25C1F5AF);
    IDelegationManager public constant delegationManager = IDelegationManager(0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A);
    IStrategy public constant sfrxETHStrategy = IStrategy(0x8CA7A5d6f3acd3A7A8bC468a8CD0FB14B6BD28b6);
    IPauserRegistry public constant pauserRegistry = IPauserRegistry(0x0c431C66F4dE941d089625E5B423D00707977060);

    uint32 public constant TASK_RESPONSE_WINDOW_BLOCK = 30;

    // ============================================================================================
    // Setup
    // ============================================================================================

    function setUp() public {

        // initialize users
        proxyOwner = _createUser("proxyOwner");
        owner = _createUser("owner");
        user = _createUser("user");
        aggregator = _createUser("aggregator");
        generator = _createUser("generator");

        // deploy empty contract
        emptyContract = address(new EmptyContract());

        // deploy proxy contracts
        taskManager = PointGuardTaskManager(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        serviceManager = PointGuardServiceManager(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        registryCoordinator = RegistryCoordinator(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        stakeRegistry = StakeRegistry(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        blsApkRegistry = BLSApkRegistry(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));
        indexRegistry = IndexRegistry(address(new TransparentUpgradeableProxy(emptyContract, address(proxyOwner), "")));

        // deploy implementation contracts and initialize
        vm.startPrank(proxyOwner);

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
        address _taskManagerImplementation = address(new PointGuardTaskManager(IRegistryCoordinator(registryCoordinator), TASK_RESPONSE_WINDOW_BLOCK));
        TransparentUpgradeableProxy(payable(address(taskManager))).upgradeTo(_taskManagerImplementation);

        // ServiceManager
        address _serviceManagerImplementation = address(new PointGuardServiceManager(IAVSDirectory(avsDirectory), IRegistryCoordinator(registryCoordinator), IStakeRegistry(stakeRegistry), PointGuardTaskManager(taskManager), owner));
        TransparentUpgradeableProxy(payable(address(serviceManager))).upgradeTo(_serviceManagerImplementation);

        vm.stopPrank();

        // initialize contracts
        _initializeRegistryCoordinator();
        _initializeTaskManager();

        // label contracts
        vm.label({ account: address(stakeRegistry), newLabel: "StakeRegistry" });
        vm.label({ account: address(blsApkRegistry), newLabel: "BLSApkRegistry" });
        vm.label({ account: address(indexRegistry), newLabel: "IndexRegistry" });
        vm.label({ account: address(registryCoordinator), newLabel: "RegistryCoordinator" });
        vm.label({ account: address(taskManager), newLabel: "TaskManager" });
        vm.label({ account: address(serviceManager), newLabel: "ServiceManager" });

        // register protocol
        string memory _pointsScriptReference = "GITHUB_URL";
        vm.prank(owner);
        serviceManager.registerProtocol(_pointsScriptReference);
    }

    // ============================================================================================
    // Tests
    // ============================================================================================

    function testCreateNewTask() public {

        taskCreatedBlock = uint32(block.number);

        IPointGuardTaskManager.Task memory _task = IPointGuardTaskManager.Task({
            protocolId: protocolId,
            user: user,
            taskCreatedBlock: taskCreatedBlock,
            quorumThresholdPercentage: quorumThresholdPercentage,
            quorumNumbers: quorumNumbers
        });

        vm.expectEmit(address(taskManager));
        emit NewTaskCreated(uint32(0), _task);

        vm.prank(generator);
        taskManager.createNewTask(
            protocolId,
            user,
            quorumThresholdPercentage,
            quorumNumbers
        );
    }

    function testRespondToTask() public {
        testCreateNewTask();

        IPointGuardTaskManager.Task memory _task = IPointGuardTaskManager.Task({
            protocolId: protocolId,
            user: user,
            taskCreatedBlock: taskCreatedBlock,
            quorumThresholdPercentage: quorumThresholdPercentage,
            quorumNumbers: quorumNumbers
        });

        IPointGuardTaskManager.TaskResponse memory _taskResponse = IPointGuardTaskManager.TaskResponse({
            referenceTaskIndex: 0,
            totalPoints: 1000,
            userPoints: 100
        });

        IBLSSignatureChecker.NonSignerStakesAndSignature memory _nonSignerStakesAndSignature;
        {
            uint32[] memory _nonSignerQuorumBitmapIndices = new uint32[](0);
            BN254.G1Point[] memory _nonSignerPubkeys = new BN254.G1Point[](0);
            BN254.G1Point[] memory _quorumApks = new BN254.G1Point[](0);
            uint256[2] memory _apkG2XY = [uint256(0), uint256(0)];
            BN254.G2Point memory _apkG2 = BN254.G2Point({
                X: _apkG2XY,
                Y: _apkG2XY
            });
            BN254.G1Point memory _sigma = BN254.G1Point(0, 0);
            uint32[] memory _quorumApkIndices = new uint32[](0);
            uint32[] memory _totalStakeIndices = new uint32[](0);
            uint32[][] memory _nonSignerStakeIndices = new uint32[][](0);
            _nonSignerStakesAndSignature = IBLSSignatureChecker.NonSignerStakesAndSignature({
                nonSignerQuorumBitmapIndices: _nonSignerQuorumBitmapIndices,
                nonSignerPubkeys: _nonSignerPubkeys,
                quorumApks: _quorumApks,
                apkG2: _apkG2,
                sigma: _sigma,
                quorumApkIndices: _quorumApkIndices,
                totalStakeIndices: _totalStakeIndices,
                nonSignerStakeIndices: _nonSignerStakeIndices
            });
        }

        IPointGuardTaskManager.TaskResponseMetadata memory _taskResponseMetadata = IPointGuardTaskManager.TaskResponseMetadata({
            taskResponsedBlock: uint32(block.number),
            hashOfNonSigners: bytes32(0)
        });

        vm.expectEmit(address(taskManager));
        emit TaskResponded(_taskResponse, _taskResponseMetadata);

        vm.prank(aggregator);
        taskManager.respondToTask(
            _task,
            _taskResponse,
            _nonSignerStakesAndSignature,
            false
        );
    }

    function testRaiseChallenge() public {
        testRespondToTask();

        IPointGuardTaskManager.TaskResponse memory _taskResponse = IPointGuardTaskManager.TaskResponse({
            referenceTaskIndex: 0,
            totalPoints: 1000,
            userPoints: 100
        });

        IPointGuardTaskManager.TaskResponseMetadata memory _taskResponseMetadata = IPointGuardTaskManager.TaskResponseMetadata({
            taskResponsedBlock: uint32(block.number),
            hashOfNonSigners: bytes32(0)
        });

        vm.expectEmit(address(taskManager));
        emit TaskChallengedSuccessfully(uint32(0), user);

        vm.prank(user);
        taskManager.raiseChallenge(
            _taskResponse,
            _taskResponseMetadata
        );
    }

    function testResolveChallengeValid() public {
        testRaiseChallenge();

        vm.expectEmit(address(taskManager));
        emit TaskChallengeResolved(uint32(0), true);

        vm.prank(owner);
        taskManager.resolveChallenge(0, true);
    }

    function testResolveChallengeInvalid() public {
        testRaiseChallenge();

        vm.expectEmit(address(taskManager));
        emit TaskChallengeResolved(uint32(0), false);

        vm.prank(owner);
        taskManager.resolveChallenge(0, false);
    }

    // ============================================================================================
    // Internal helpers
    // ============================================================================================

    function _createUser(string memory _name) internal returns (address payable) {
        address payable _user = payable(makeAddr(_name));
        vm.deal({ account: _user, newBalance: 100 ether });
        return _user;
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
            aggregator, // _aggregator
            generator // _generator
        );
    }
}
