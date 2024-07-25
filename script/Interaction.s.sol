//SPDX-License-Identifier : MIT;
pragma solidity ^0.8.18;

import {helperConfig} from "./helperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script, console} from "forge-std/Script.sol";
import {LinkToken} from "../test/mocks/linktoken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {rafle} from "../src/Lottery.sol";

contract createSubscription is Script {
    function createConfiguration() public returns (uint64) {
        helperConfig subscription_helper_config = new helperConfig();
        (, , , address vrfCordinaor, , ) = subscription_helper_config
            .contructor_parameters();
        return creatSubscription(vrfCordinaor);
    }

    function creatSubscription(address vfrContract) public returns (uint64) {
        console.log("Creating subscription");
        vm.startBroadcast();
        uint64 s_id = VRFCoordinatorV2Mock(vfrContract).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription Created");
        return s_id;
    }

    function getSubscription() public returns (uint64) {
        return createConfiguration();
    }
}

contract fundSubscription is Script {
    uint96 public constant amount = 2 ether;

    function fundTheSubscription() public {
        helperConfig subscription_helper_config = new helperConfig();
        (
            ,
            ,
            uint64 s_subscriptionId,
            address vrfCordinaor,
            ,
            address linkTokensAddress
        ) = subscription_helper_config.contructor_parameters();
        fundingSubscription(s_subscriptionId, vrfCordinaor);
    }

    function fundingSubscription(
        uint64 _s_subscriptionId,
        address _vrfCordinaor
    ) public {
        vm.startBroadcast();
        VRFCoordinatorV2Mock(_vrfCordinaor).fundSubscription(
            _s_subscriptionId,
            amount
        );
        vm.stopBroadcast();
    }

    function run() external {
        fundTheSubscription();
    }
}

contract addConsumer is Script {
    function getConsumer(address _consumer) public {
        helperConfig subscription_helper_config = new helperConfig();
        (
            ,
            ,
            uint64 s_subscriptionId,
            address vrfCordinaor,
            ,

        ) = subscription_helper_config.contructor_parameters();

        addConsumerFinal(vrfCordinaor, s_subscriptionId, _consumer);
    }

    function addConsumerFinal(
        address vrfCordinator,
        uint64 s_subID,
        address consumer
    ) public {
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vrfCordinator).addConsumer(s_subID, consumer);
        vm.stopBroadcast();
    }

    function run() external {
        address rafleAddress = DevOpsTools.get_most_recent_deployment(
            "rafle",
            block.chainid
        );
        getConsumer(rafleAddress);
    }
}
