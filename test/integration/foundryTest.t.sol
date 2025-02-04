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
    address LinkTokenAddress;

    address public bilal = makeAddr("bilal");

    function setUp() external {
        console.log("this is test contract address :- ",address(this));
        deployScript testDeployScript = new deployScript();
        (testRafleContract, testNetworkConfig) = testDeployScript.deployRafle();
        (
            entranceFee,
            timeLimit,
            subscriptionId,
            vrfCoordinator,
            keyHash,
            LinkTokenAddress
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

    function testFeeAvailableButLotteryIsNotOpened() public {
        //arrange
        vm.deal(bilal, 2 ether);
        vm.prank(bilal);
        //act
        testRafleContract.closeRafle();
        vm.expectRevert(rafleCotnract.Rafle_contractStateNotOpened.selector);
        testRafleContract.enterRafle{value: 1 ether}("bilal", "country");

        //assert
        assert(testRafleContract.getUserQuantity() == 0);
        assert(testRafleContract.getContractBalance() == 0);
    }

    /*//////////////////////////////////////////////////////////////
                 BALANCE ISN'T PRESENT BUT STATE IS CLOSED
    //////////////////////////////////////////////////////////////*/

    function testFeeNotAvailableButLotteryIsOpen() public {
        //arrange
        vm.deal(bilal, 0.9 ether);
        vm.prank(bilal);
        bytes memory errorData = abi.encodeWithSelector(
            rafleCotnract.Rafle_insufficientEntranceFee.selector,
            0.9 ether, // msg.value
            1 ether // i_entranceFee
        );
        //act

        vm.expectRevert(errorData);
        testRafleContract.enterRafle{value: 0.9 ether}("bilal", "country");

        //assert
        assert(testRafleContract.getState() == 0);
        assert(testRafleContract.getUserQuantity() == 0);
        assert(testRafleContract.getContractBalance() == 0);
    }

    /*//////////////////////////////////////////////////////////////
    MAKING SURE THAT EVENT EMIT ITSELF WHEN PERSON ENTERS INTO RAFLE
    //////////////////////////////////////////////////////////////*/

    function testEventEmitItself() public PersonHasBalance {
        //Arrange
        //ACT
        vm.expectEmit(true, true, false, false, address(testRafleContract));
        emit rafleCotnract.userEntered(bilal, "pakistan");
        testRafleContract.enterRafle{value: entranceFee}("bilal", "pakistan");
    }

    /*//////////////////////////////////////////////////////////////
                       TRIGGERING PERFORM UP KEEP
    //////////////////////////////////////////////////////////////*/
    // logic
    //make sure that checkup keep constrains properly meet the criteria
    //then trigger perform up keep
    //then make sure when you enter into the rafle the enternce is failed
    //state of the contract is closed

    function testEnterenceIntoRafleFailsWhenPerformUpKeepIsInitiated()
        public
        UptoFivePersionIntoContract
    {
        //act
        vm.warp(block.timestamp + timeLimit + 1);

        //act and assert
        //Does this function called below will require me any person to initiate it or if that is okay ?
        // vm.prank(bilal);
        testRafleContract.performUpkeep("");
        vm.prank(bilal);
        vm.deal(bilal, 2 ether);
        vm.expectRevert(rafleCotnract.Rafle_contractStateNotOpened.selector);
        testRafleContract.enterRafle{value: entranceFee}("bilal", "pakistan");
    }

    /** Modifiers */
    modifier PersonHasBalance() {
        vm.deal(bilal, entranceFee);
        vm.prank(bilal);
        _;
    }

    modifier UptoFivePersionIntoContract() {
        for (uint256 a = 1; a <= 5; a++) {
            string memory integerConvertedToString = vm.toString(a);
            address addr = makeAddr(integerConvertedToString); // Generate a deterministic address
            vm.deal(addr, entranceFee); // Assign balance to the address
            vm.startPrank(addr); // Start prank for the address
            testRafleContract.enterRafle{value: entranceFee}("abc", "pakistan"); // Enter the raffle
            vm.stopPrank(); // Stop prank
        }
        _;
    }
}
