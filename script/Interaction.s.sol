//SPDX-License-Identifier : MIT;
pragma solidity ^0.8.18;

import {helperConfig} from "./helperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script, console} from "forge-std/Script.sol";


contract createSubscription is Script {

    function createLocalConfig() public returns (uint64) {
        helperConfig subscription_helper_config = new helperConfig();
        (
            ,
            ,
            uint64 s_subscriptionId,
            address vrfCordinaor,
            ,

        ) = subscription_helper_config.contructor_parameters();
        return creatSubscription(vrfCordinaor);
    }

    function creatSubscription(address vfrContract) public returns (uint64) {
        console.log("Creating subscription");
        vm.startBroadcast();
        VRFCoordinatorV2Mock(vfrContract).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription Created");
    }

    function getSubscription() public returns (uint64) {
        return createLocalConfig();
    }
}

contract fundSubscription {
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

        fundingSubscription(s_subscriptionId,vrfCordinaor,linkTokensAddress);

    }

    function fundingSubscription(uint64 _s_subscriptionId, address _vrfCordinaor,address _linkTokensAddress ) public {
        
    }

    function run() external {
        fundTheSubscription();
    }
}
