//SPDX-License-Identifier : MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {NetworkConfiguration} from "./networkConfiguration.s.sol";

// As per of thie script we will be deploying our contracts appropriately on multiple networks


contract deployScript is Script {
    //achieve modularity that is break down the processes
    
    function run() public {

    }

    function deployRafle() public {
    NetworkConfiguration networkConfig = receiveNetworkConfig();
    NetworkConfiguration.networkParams memory arguments =  networkConfig.getConfiguration();
    
    }

    function receiveNetworkConfig() public returns(NetworkConfiguration ){
        NetworkConfiguration networkContract = new NetworkConfiguration();
        return networkContract;
    }

}

