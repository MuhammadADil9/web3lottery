//SPDX-License-Identifier : MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {NetworkConfiguration} from "./networkConfiguration.s.sol";
import {rafleCotnract} from "../src/rafle.sol";
import {subscriptionContract} from "./interactions.s.sol";
import {ConsumerAddition} from "./interactions.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {fundSubscription} from "./interactions.s.sol";

contract deployScript is Script {
    NetworkConfiguration networkConfig;
    NetworkConfiguration.networkParams public arguments;

    function run() public {}

    function deployNetworkConfiguration()
        public
        returns (NetworkConfiguration)
    {
        NetworkConfiguration NetworkConfig = new NetworkConfiguration();
        return NetworkConfig;
    }

    function deployRafle()
        public
        returns (rafleCotnract, NetworkConfiguration)
    {
        networkConfig = deployNetworkConfiguration();
        arguments = networkConfig.getConfiguration();

        // time to create subscription ID
        if (arguments.subscriptionId == 0) {
            subscriptionContract tempContract = new subscriptionContract();
            (arguments.subscriptionId) = tempContract.createSubscription(
                address(networkConfig)
            );
            networkConfig.updateChainConfig(block.chainid, arguments);
            // NetworkConfiguration.chainConfiguration[block.chainid].subscriptionId = id;
            console.log("The subscription id is :- ", arguments.subscriptionId);
        }

        fundSubscription fundingContract = new fundSubscription();
        fundingContract.fundSubscriptionBasedOnId(address(networkConfig));



        vm.startBroadcast();
        rafleCotnract _rafleContract = new rafleCotnract(
            arguments.entranceFee,
            arguments.timeLimit,
            arguments.subscriptionId,
            arguments.vrfCoordinator,
            arguments.keyHash
        );
        vm.stopBroadcast();

        // Now adding the consumer
        
        ConsumerAddition consumerContract = new ConsumerAddition();
        consumerContract.addConsumer(
            address(_rafleContract),
            address(networkConfig)
        );

        return (_rafleContract, networkConfig);
    }
}
