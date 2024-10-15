//SPDX-License-Identifier : MIT
pragma solidity ^0.8.9;

import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script} from "lib/forge-std/src/Script.sol";
import {VmSafe} from "lib/forge-std/src/Vm.sol";

error helpferConfig_incorrectChain();

contract helperConfig is Script {
    uint256 public constant ETH_SAP_ID = 11155111;
    uint256 public constant LOCAL_ID = 31337;
    uint256 public key = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    //Randomly selected values
    //Still need to identify them
    uint96 public constant baseFee = 1e18;
    uint96 public constant gasPriceLink = 1e15;

    struct params {
        address vrfCordinator;
        uint32 _callBackGas;
        bytes32 _keyhash;
        uint256 _subId;
    }

    params public parameters;

    // mapping(uint256 chainID => params) public networkConfiguration;

    constructor() {
        //why are we doing this ?
        // networkConfiguration[ETH_SAP_ID] = sapETH();
    }

    function decideConfiguration(
        uint256 ChainID
    ) public  returns (params memory) {
        //Will the first 'if' condition ever fail ?
        // if(networkConfiguration[ChainID].vrfCordinator != address(0)){
        if (ChainID == 11155111) {
            //            return networkConfiguration[ChainID];
            return sapEth();
        } else if (ChainID == LOCAL_ID) {
            return AnvilConfiguration();
        } else {
            revert helpferConfig_incorrectChain();
        }
    }

    //final function for modularity

    function getConfiguration() public  returns (params memory) {
        return decideConfiguration(block.chainid);
    }

    function sapEth() public view returns (params memory) {
        return
            params({
                vrfCordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                _callBackGas: 50000,
                _keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                _subId: 0
            });
    }

    function AnvilConfiguration() public  returns (params memory) {
        //will return me local chain configuration
        if (parameters.vrfCordinator != address(0)) {
            return parameters;
        }

        //first we need to initialize mock contract which is a copy of exact same contract deployed on chian
        // vm.startbroadcast();
        vm.startBroadcast();
        VRFCoordinatorV2Mock mockVrfCordinator = new VRFCoordinatorV2Mock(baseFee,gasPriceLink);
        vm.stopBroadcast();

        parameters = params({
            vrfCordinator: address(mockVrfCordinator),
            _callBackGas: 50000,
            _keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            _subId: 0
        });
    }
}
