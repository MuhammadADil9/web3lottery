//SPDX-License-Identifier : MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract constantWords {
    uint256 public constant sepolia_ID = 11155111;
    uint256 public constant local_ID = 31337;
}

// The purpose is to achieve modularity by breaking down everythings into chunks

contract NetworkConfiguration is Script, constantWords {

    /**state variables */
    networkParams public localConfiguration;
    mapping(uint256 chainConfiguration => networkParams) networkConfigMapping;

    /**Functions */
    constructor() {
        // by default when this script will be initialized it will set the current mapping satus to this struct
        networkConfigMapping[sepolia_ID] = getSepoliaConfiguration();
    }

    function getConfigurationByChainId(
        uint256 chainID
    ) public returns (networkParams memory) {
        if (chainID == sepolia_ID) {
            return networkConfigMapping[chainID];
        } else if (chainID == local_ID) {
            return getLocalConfiguration();
        }
    }

    //break down everythings down to the chunks for achieving modularoty 
    // function for getting sepolia configurations is perforiming single thing
    // function for getting fetching and storing local environment is performing single thing
    // however function for getting the configuration with the help of chain id is performing 2 things 
    // therefore break it down into chunk 
    
    //This will return network configuration   
    function getConfiguration() public  returns(networkParams memory){
        return getConfigurationByChainId(block.chainid);
    }

    function getSepoliaConfiguration()
        public
        pure
        returns (networkParams memory)
    {
        return
            networkParams({
                entranceFee: 1 ether,
                timeLimit: 60,
                subscriptionId: 97802776641483268026869314607947010537980447778541042774586935978233989077328,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
            });
    }

    function getLocalConfiguration() public returns (networkParams memory) {
        VRFCoordinatorV2_5Mock vrf_mockContract;
        if (localConfiguration.vrfCoordinator != address(0)) {
            return localConfiguration;
        }

        vm.startBroadcast();
        vrf_mockContract = new VRFCoordinatorV2_5Mock(1e5,1e5,1e10); 
        vm.stopBroadcast();

        localConfiguration = networkParams({
            entranceFee: 1 ether,
            timeLimit: 60,
            subscriptionId: 0,
            vrfCoordinator: address(vrf_mockContract),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
        });
        networkConfigMapping[31337] = localConfiguration;
        return localConfiguration;
    }

    /** struct */
    struct networkParams {
        uint256 entranceFee;
        uint256 timeLimit;
        uint256 subscriptionId;
        address vrfCoordinator;
        bytes32 keyHash;
    }
}

// so far we created two functions that will help us to give the appropriate configuration one for the sepolia network and another one for the local network whicn is uncomplete
// the question is that how these will be now fetched ?

// like what is the purpose of this script
// purpose is to generate the paramerters accordingly as per of the network.

// one type of parameters must be generated for the sepolia
// one should be generated for local

// achiving moularity ?

// why did we create a local configuration variable of struct ?
// why did we instiantie the sepolia struct
