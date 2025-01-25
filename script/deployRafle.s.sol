//SPDX-License-Identifier : MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {NetworkConfiguration} from "./networkConfiguration.s.sol";
import {rafleCotnract} from "../src/rafle.sol";
// As per of thie script we will be deploying our contracts appropriately on multiple networks


contract deployScript is Script {
    //achieve modularity that is break down the processes
    NetworkConfiguration networkConfig;
    NetworkConfiguration.networkParams public arguments;
    

    function run() public {
    }

    function deployRafle() public returns(rafleCotnract,NetworkConfiguration)  {
    networkConfig = new NetworkConfiguration();
    arguments =  networkConfig.getConfiguration();
    

    vm.startBroadcast();
    rafleCotnract _rafleContract = new rafleCotnract(arguments.entranceFee,arguments.timeLimit, arguments.subscriptionId, arguments.vrfCoordinator, arguments.keyHash);
    vm.stopBroadcast();
    
    return (_rafleContract,networkConfig);
    }

    // function receiveNetworkConfig() public returns(NetworkConfiguration ){
    //     NetworkConfiguration networkContract = new NetworkConfiguration();
    //     return networkContract;
    // }

}

