//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {NetworkConfiguration} from "./networkConfiguration.s.sol";
import {Script,console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
// import {}

contract subscriptionContract is Script { 
    function run() public {
        createSubscriptionUsingConfig();
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


