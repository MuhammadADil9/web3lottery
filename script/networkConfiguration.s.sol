// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

abstract contract constantWords {
    uint256 public constant sepolia_ID = 11155111;
    uint256 public constant local_ID = 31337;
}

contract NetworkConfiguration is Script, constantWords {
    /** State variables */
    mapping(uint256 => networkParams) public chainConfiguration;

    /** Struct */
    struct networkParams {
        uint256 entranceFee;
        uint256 timeLimit;
        uint256 subscriptionId;
        address vrfCoordinator;
        bytes32 keyHash;
        address linkToken;
    }

    /** Constructor */
    constructor() {}

    /** Functions */
    function getConfigurationByChainId(
        uint256 chainID
    ) public returns (networkParams memory) {
        if (chainConfiguration[chainID].vrfCoordinator != address(0)) {
            return chainConfiguration[chainID];
        }

        if (chainID == sepolia_ID) {
            chainConfiguration[sepolia_ID] = getSepoliaConfig();
        } else {
            chainConfiguration[local_ID] = getAnvilConfig();
        }
        return chainConfiguration[chainID];
    }

    // ----------------------------------------------------------------------

    function getConfiguration() public returns (networkParams memory) {
        return getConfigurationByChainId(block.chainid);
    }

    // ------------------------------------------------------------------------

    function getSepoliaConfig() public pure returns (networkParams memory) {
        return
            networkParams({
                entranceFee: 1 ether,
                timeLimit: 60,
                subscriptionId: 0,
                vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    // --------------------------------------------------------------------

    function getAnvilConfig() public returns (networkParams memory) {
        VRFCoordinatorV2_5Mock vrf_mockContract;
        LinkToken token;

        vm.startBroadcast();
        vrf_mockContract = new VRFCoordinatorV2_5Mock(1e5, 1e5, 1e10);
        token = new LinkToken();
        vm.stopBroadcast();

        console.log(
            "VRF Coordinator address is this  :- ",
            address(vrf_mockContract)
        );
        console.log("Link Token address is  :- ", address(token));

        return
            networkParams({
                entranceFee: 1 ether,
                timeLimit: 60,
                subscriptionId: 0,
                vrfCoordinator: address(vrf_mockContract),
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                linkToken: address(token)
            });
    }

    function GetParametersConfigurationByPlacingId(
        uint256 chain_id
    ) public view returns (networkParams memory) {
        return chainConfiguration[chain_id];
    }

    function updateChainConfig(
        uint256 chainID,
        networkParams memory params
    ) public {
        chainConfiguration[chainID] = params;
    }
}

// Code heirarchy is that
// There will be a empty constructor
// There will be a function that will return me the configuration.
// There will be another function this function will either return or generate me the instruction based on the chain id
// then there will be two bottom functions supporting multiple chains configuration
// then there will be another function that will enable me to pay for a particular subscription

// currently initilizing the structs within the contract and not having a appropriate method for feteching the configurations were failing me badly.
// let's give another try by initilizing the contract properly and placing a correct method for fetching the setings.

// consequencs
// this will be linked contract where each contract has a direct link with another contract or dependency between them might be high
