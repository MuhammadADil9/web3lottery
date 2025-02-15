//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {NetworkConfiguration} from "./networkConfiguration.s.sol";
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {constantWords} from "./networkConfiguration.s.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";



contract subscriptionContract is Script, constantWords {
    function run() public {}
 
    function createSepoliaSubscription(address vrf) public returns (uint256) {
        //VRFCordinator will be of sepolia
        vm.startBroadcast();
        uint256 id = IVRFCoordinatorV2Plus(vrf).createSubscription();
        vm.stopBroadcast();
        return id;
    }

    function SepoliaSubscription(
        address NetworkConfigs
    ) public returns (uint256) {
        NetworkConfiguration.networkParams
            memory tempArguments = NetworkConfiguration(NetworkConfigs)
                .getConfiguration();
        return createSepoliaSubscription(tempArguments.vrfCoordinator);
    }

    function createAnvilSubscription(address vrf) public returns (uint256) {
        //VRFCordinator will be of local anvil chian that is mock
        vm.startBroadcast();
        uint256 id = VRFCoordinatorV2_5Mock(vrf).createSubscription();
        vm.stopBroadcast();
        return id;
    }

    function AnvilSubscription(
        address NetworkConfigs
    ) public returns (uint256) {
        NetworkConfiguration.networkParams
            memory tempArguments = NetworkConfiguration(NetworkConfigs)
                .getConfiguration();
        return createAnvilSubscription(tempArguments.vrfCoordinator);
    }

    function createSubscription(
        address NetworkConfigsAddress
    ) public returns (uint256) {
        if (block.chainid == sepolia_ID) {
            console.log("creating sepolia Configuration");
            return SepoliaSubscription(NetworkConfigsAddress);
        } else {
            console.log("creating anvil subscription");
            return AnvilSubscription(NetworkConfigsAddress);
        }
    }
}

contract ConsumerAddition is Script, constantWords {
   

    function addSepoliaConsumer(
        uint256 id,
        address consumerAddress,
        address vrfCordinator
    ) public {
        vm.startBroadcast();
        IVRFCoordinatorV2Plus(vrfCordinator).addConsumer(id, consumerAddress);
        vm.stopBroadcast();
    }

    function SepoliaConsumer(
        address consumerAddress,
        address networkConfig
    ) public {
        NetworkConfiguration.networkParams
            memory tempArguments = NetworkConfiguration(networkConfig)
                .GetParametersConfigurationByPlacingId(block.chainid);
        addSepoliaConsumer(
            tempArguments.subscriptionId,
            consumerAddress,
            tempArguments.vrfCoordinator
        );
    }

    function addAnvilConsumer(
        uint256 id,
        address consumerAddress,
        address vrfCordinator
    ) public {
        // address contractAddress = DevOpsTools.get_most_recent_deployment("rafleCotnract",block.chainid); 
        // console.log("The contract address as per devops tool is :- ",contractAddress);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCordinator).addConsumer(id, consumerAddress);
        vm.stopBroadcast();
    }

    function AnvilConsumer(
        address consumerAddress,
        address networkConfig
    ) public {
        NetworkConfiguration.networkParams
            memory tempArguments = NetworkConfiguration(networkConfig)
                .GetParametersConfigurationByPlacingId(block.chainid);
                console.log("consumer address is :- ",consumerAddress);
        addAnvilConsumer(
            tempArguments.subscriptionId,
            consumerAddress,
            tempArguments.vrfCoordinator
        );
    }

    function addConsumer(
        address consumerAddress,
        address networkConfig
    ) public {
      
        if (block.chainid == sepolia_ID) {
            SepoliaConsumer(consumerAddress, networkConfig);
        } else {
            AnvilConsumer(consumerAddress, networkConfig);
        }
    }
}

contract fundSubscription is Script, constantWords {
    function run() public {}

    uint256 public constant AmountToFund = 3 ether;

    function fundSubscriptionBasedOnId(address networkConfig) public {
        if (block.chainid == sepolia_ID) {
            fundSepolia(networkConfig);
        } else {
            fundLocalSub(networkConfig);
        }
    }

    function fundSepolia(address networkConfig) public {
        NetworkConfiguration.networkParams
            memory tempArguments = NetworkConfiguration(networkConfig)
                .GetParametersConfigurationByPlacingId(block.chainid);
        console.log(
            "subscription id that will be funded is :- ",
            tempArguments.subscriptionId
        );
        vm.startBroadcast();
        LinkTokenInterface(0x779877A7B0D9E8603169DdbD7836e478b4624789)
            .transferAndCall(
                tempArguments.vrfCoordinator,
                AmountToFund,
                abi.encode(tempArguments.subscriptionId)
            );
        vm.startBroadcast();
    }

    function fundLocalSub(address networkConfig) public {
        NetworkConfiguration.networkParams
            memory tempArguments = NetworkConfiguration(networkConfig)
                .GetParametersConfigurationByPlacingId(block.chainid);
        
        uint256 idd = tempArguments.subscriptionId;
        address vrf = tempArguments.vrfCoordinator;

        console.log(" the subscription  id is :- ", idd, " the cordinator address is :- ",vrf);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(tempArguments.vrfCoordinator).fundSubscription(tempArguments.subscriptionId,AmountToFund*10000);
       
        vm.stopBroadcast();
    }
}
