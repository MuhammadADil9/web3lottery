//SPDX-License-Identifier : MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {deploy} from "../../script/deploy.s.sol";
import {rafle} from "../../src/Lottery.sol";
import {helperConfig} from "../../script/helperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract test is Test {
    event fundersInfo(uint256 indexed amount, string indexed name);

    rafle public rafleTest;
    deploy public deployTest;
    helperConfig public hConfig;
    address public players = makeAddr("player");
    uint256 public amount = 5 ether;
    uint256 public _interval;
    bytes32 public gasLanePrice;
    uint64 public s_subscriptionId;
    address public vrfCordinaor;
    uint32 public cb_gasLimit;
    address public linkAddress;

    modifier PayUpToFive() {
        address one = makeAddr("one");
        address two = makeAddr("two");
        address three = makeAddr("three");
        address four = makeAddr("four");
        address five = makeAddr("five");

        vm.deal(one, 10 ether);
        vm.deal(two, 10 ether);
        vm.deal(three, 10 ether);
        vm.deal(four, 10 ether);
        vm.deal(five, 10 ether);

        vm.prank(one);
        rafleTest.fund{value: 5 ether}("a");

        vm.prank(two);
        rafleTest.fund{value: 5 ether}("b");

        vm.prank(three);
        rafleTest.fund{value: 5 ether}("c");

        vm.prank(four);
        rafleTest.fund{value: 5 ether}("d");

        vm.prank(five);
        rafleTest.fund{value: 5 ether}("e");
        _;
    }

    function setUp() public {
        deployTest = new deploy();
        (rafleTest, hConfig) = deployTest.run();

        (
            _interval,
            gasLanePrice,
            s_subscriptionId,
            vrfCordinaor,
            cb_gasLimit,
            linkAddress
        ) = hConfig.contructor_parameters();
    }

    function testContractInitialization() public {
        assert(rafleTest.getState() == rafle.contractState.open);
    }

    function testFundingFunction() public {
        vm.deal(players, amount);
        vm.prank(players);
        vm.expectRevert(
            rafle.rafle_insert_minimum_amount_for_entering_into_rafle.selector
        );
        rafleTest.fund{value: 1e9}("adil");
    }

    function testContractFunded() public {
        vm.deal(players, amount);
        vm.prank(players);
        rafleTest.fund{value: 3 ether}("adil");
    }

    function testFundedArray() public {
        vm.deal(players, amount);
        vm.prank(players);
        rafleTest.fund{value: 3 ether}("arslan");
        uint256 val = 1;
        assert(rafleTest.getFundersLenth() == val);
    }

    function testFundersArrayShouldNotExceed() public {
        vm.deal(players, amount);
        vm.prank(players);
        vm.expectRevert();
        rafleTest.fund{value: 1e10 ether}("arslan");
        uint256 _length = 0;
        uint256 arrayLength = rafleTest.getFundersLenth();
        vm.expectRevert();
        assert(arrayLength == 1);
    }

    //checing if emit happens
    function testEmitHappening() public {
        vm.deal(players, amount);
        vm.prank(players);
        vm.expectEmit(true, true, false, false, address(rafleTest));
        emit fundersInfo(1 ether, "adil");
        rafleTest.fund{value: 1 ether}("adil");
    }

    // it will fund when the state will be down
    function testFundWhenStateIsDown() public PayUpToFive {
        vm.warp(block.timestamp + _interval + 1);
        vm.roll(block.number + 2);
        rafleTest.performUpkeep("");
        ////
        vm.deal(players, amount);
        vm.prank(players);
        vm.expectRevert();
        rafleTest.fund{value: 3 ether}("adil");
    }

    //Test when all the condition meet
    function testCheckUpKeep() public PayUpToFive {
        vm.warp(block.timestamp + _interval + 2);
        (bool checkUpKeep, ) = rafleTest.checkUpkeep("");

        assert(checkUpKeep);
    }

    //when the contract condition is not OPEN
    function testCheckUpKeepFailOne() public PayUpToFive {
        vm.warp(block.timestamp + _interval + 50);
        rafleTest.turnOfState();
        vm.expectRevert(abi.encodeWithSignature("rafle_contractStateIsNotOpen()"));
        rafleTest.checkUpkeep("");
        
    }

    // checkup keep should fail when there are not sufficient people in the contract

    function testCheckUpKeepFailTwo() public {
        vm.warp(block.timestamp + _interval + 50);
        vm.expectRevert(
            abi.encodeWithSignature("rafle_not_enough_participants()")
        );
        rafleTest.checkUpkeep("");
        // assert(!checkUpKeep);
    }

    // checkup keep should fail when time limit is not passed
    function testCheckUpKeepFailThree() public PayUpToFive {
        // vm.warp(block.timestamp + _interval + 50);
        vm.expectRevert(
            abi.encodeWithSignature("rafle_time_limit_not_exceeded()")
        );
        rafleTest.checkUpkeep("");
        // assert(!checkUpKeep);
    }

    // perform up keep has to fail because checkup keep is not fulfilled
    function testperformupkeepshouldreturnfalse() public {
        vm.expectRevert();
        rafleTest.performUpkeep("");
    }

    // perform has to work because checkup conditions are all satisfied
    function testReturnRandomWords() public PayUpToFive {
        vm.warp(block.timestamp + _interval + 2);
        vm.roll(block.number + 4);
        rafleTest.performUpkeep("");
    }


    // Random words will fail because performup keep is not called
    function testRandomWordsShouldFail() public {
        
    }

}
