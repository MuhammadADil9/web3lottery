//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {deployScript} from "../../script/deployRafle.s.sol";
import {rafleCotnract} from "../../src/rafle.sol";
import {Test,console} from "forge-std/Test.sol";
import {NetworkConfiguration} from "../../script/networkConfiguration.s.sol";

contract lotteryTest is Test {
    //get the parameters and the deployed contract itself
    NetworkConfiguration testNetworkConfig;
    rafleCotnract testRafleContract;

    uint256 public constant ENTRANCE_FEE = 1 ether;
    // There are some global cheat codes that foundry gives you
    // one of them is makeAddr that makes a address from the given input
    // address public testPublicUser = makeAddr("people");
    uint256 entranceFee;
    uint256 timeLimit;
    uint256 subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;

    // function setUp() external {
    //     deployScript testDeployScript = new deployScript();
    //     (testRafleContract, testNetworkConfig) = testDeployScript.deployRafle();
    //     (entranceFee,timeLimit,subscriptionId,vrfCoordinator,keyHash) = testDeployScript.arguments();   
    // }

function setUp() external {
    deployScript testDeployScript = new deployScript();
    (testRafleContract, testNetworkConfig) = testDeployScript.deployRafle();
    (entranceFee, timeLimit, subscriptionId, vrfCoordinator, keyHash) = testDeployScript.arguments();

    console.log("vrfCoordinator:", vrfCoordinator);
    // console.log("keyHash:", keyHash);
    console.log("entranceFee:", entranceFee);
    console.log("timeLimit:", timeLimit);
    console.log("subscriptionId:", subscriptionId);
}
    // Test that the contract state should be open initally
    function testContractInitialState() public view {
        assert(testRafleContract.getState() == rafleCotnract.contractStatus.open);
    }
}
