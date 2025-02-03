//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {NetworkConfiguration} from "./networkConfiguration.s.sol";
import {Script,console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {constantWords} from "networkConfiguration.s.sol";

contract subscriptionContract is Script,constantWords { 
    function run() public {
        // createSubscriptionUsingConfig();
    }

    function createSepoliaSubscription(address vrf) public returns(uint256){
        //VRFCordinator will be of sepolia 
        uint256 id = irvfCordinator(vrf).createSubscription();
        return id;        
    } 
    
    function SepoliaSubscription(address vrf) public returns (uint256){
        return createSepoliaSubscription();
    } 


    function createAnvilSubscription(address vrf) public returns(uint256){
        //VRFCordinator will be of local anvil chian that is mock 
        uint256 id = VRFCoordinatorV2_5Mock(vrf).createSubscription();
        return id;        
    } 
    
    function AnvilSubscription(address vrf) public returns (uint256){
        return createSepoliaSubscription();
    } 
    
    function createSubscription(address vrf) public returns(uint256){
        if(block.chainid==)
    }

    function createSubscriptionUsingConfig() public returns(uint256 id,address vrfCordinatorAddres){ 
        NetworkConfiguration configurationContract = new NetworkConfiguration();
        address vrfCordinatorAddress =   configurationContract.getConfiguration().vrfCoordinator;
        (id,vrfCordinatorAddres) = createSub(vrfCordinatorAddress);
    }

    function createSub(address cordinatorAddress) public returns(uint256,address) {
        console.log("creating the subscription");
        vm.startBroadcast(); 
        uint256 subscriptionID = VRFCoordinatorV2_5Mock(cordinatorAddress).createSubscription();
        vm.stopBroadcast();
        console.log("subscription Created :- ",subscriptionID);
        return (subscriptionID,cordinatorAddress);
    }
    
}



contract fundSubscription {
    uint256 public constant AmountToFund = 3 ether;

    function fundSubscriptionUsingConfig() public {
    NetworkConfiguration configurationContract = new NetworkConfiguration();
    address vrfCordinatorAddress = configurationContract.getConfiguration().vrfCoordinator;
    uint256 subID = configurationContract.getConfiguration().subscriptionId;
    fundSub(subID,vrfCordinatorAddress);
    }

    function fundSub(uint256 subID , address vrfCordinatorAddress ) public {

    }

}


