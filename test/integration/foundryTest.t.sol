//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {deployScript} from "../../script/deployRafle.s.sol";
import {rafleCotnract} from "../../src/rafle.sol";
import {Test, console} from "forge-std/Test.sol";
import {NetworkConfiguration} from "../../script/networkConfiguration.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract lotteryTest is Test {
    //get the parameters and the deployed contract itself
    NetworkConfiguration testNetworkConfig;
    rafleCotnract testRafleContract;

    // There are some global cheat codes that foundry gives you
    // one of them is makeAddr that makes a address from the given input
    // address public testPublicUser = makeAddr("people");
    uint256 entranceFee;
    uint256 timeLimit;
    uint256 subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;

    address public bilal = makeAddr("bilal");

    function setUp() external {
        deployScript testDeployScript = new deployScript();
        (testRafleContract, testNetworkConfig) = testDeployScript.deployRafle();
        (
            entranceFee,
            timeLimit,
            subscriptionId,
            vrfCoordinator,
            keyHash
        ) = testDeployScript.arguments();

        console.log("vrfCoordinator:", vrfCoordinator);
        // console.log("keyHash:", keyHash);
        console.log("entranceFee:", entranceFee);
        console.log("timeLimit:", timeLimit);
        console.log("subscriptionId:", subscriptionId);
    }

    /*//////////////////////////////////////////////////////////////
                              RAFLE STATE
    //////////////////////////////////////////////////////////////*/
    function testContractInitialState() public view {
        assert(testRafleContract.getState() == 0);
    }

    /*//////////////////////////////////////////////////////////////
          MAKING SURE THAT PERSON IS ABLE TO ENTER INTO RAFLE IF EVERYTHING GOES WELL
    //////////////////////////////////////////////////////////////*/

    function testPersonIsAbleToEnterIntoRafle() public {
        //arrange
        vm.deal(bilal, 2 ether);
        vm.prank(bilal);
        //act
        testRafleContract.enterRafle{value: 1.5 ether}("bilal", "country");
        //assert
        assert(testRafleContract.getContractBalance() > entranceFee);
        assert(testRafleContract.getContractBalance() == 1.5 ether);
        assert(2 ether > entranceFee);
        assert(testRafleContract.getState() == 0);
        assert(testRafleContract.getUserQuantity() == 1);
    }

    /*//////////////////////////////////////////////////////////////
              NO ONE WILL ENTER INTO RAFLE WITHOUT BALANCE
    //////////////////////////////////////////////////////////////*/

    function testPersonIsNotAbleToEnterIntoRafle() public {
        //arrange
        vm.deal(bilal, 2 ether);
        vm.prank(bilal);
        bytes memory errorData = abi.encodeWithSelector(
            rafleCotnract.Rafle_insufficientEntranceFee.selector,
            0.9 ether, // msg.value
            1 ether // i_entranceFee
        );
        //act
        vm.expectRevert(errorData);
        // vm.expectRevert(rafleCotnract.Rafle_insufficientEntranceFee(0.9 ether,1 ether));
        testRafleContract.enterRafle{value: 0.9 ether}("bilal", "country");
        vm.deal(bilal, 5 ether);
        vm.prank(bilal);

        testRafleContract.closeRafle();
        //assert
        vm.expectRevert(rafleCotnract.Rafle_contractStateNotOpened.selector);
        // assert(testRafleContract.getState() == 0);
        testRafleContract.enterRafle{value: 2 ether}("bilal", "country");
        assert(testRafleContract.getUserQuantity() == 0);
        assert(testRafleContract.getContractBalance() == 0);
    }

    /*//////////////////////////////////////////////////////////////
               BALANCE IS PRESENT BUT STATE IS NOT OPENED
    //////////////////////////////////////////////////////////////*/

}
