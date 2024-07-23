//SPDX-License-Identifier : MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {deploy} from "../script/deploy.s.sol";
import {rafle} from "../src/Lottery.sol";
import {helperConfig} from "../script/helperConfig.s.sol";

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

    modifier PayUpToFive{
        address one = makeAddr("one");
        address two = makeAddr("two");
        address three = makeAddr("three");
        address four = makeAddr("four");
        address five = makeAddr("five");

        vm.deal(one, 10 ether);
        vm.deal(one, 10 ether);
        vm.deal(one, 10 ether);
        vm.deal(one, 10 ether);
        vm.deal(one, 10 ether);

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
            cb_gasLimit
        ) = hConfig.contructor_parameters();
    }

    function testStateisClosed() public PayUpToFive {

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
        rafleTest.fund{value: 1e9}("arslan");
    }

    function testContractFunded() public {
        vm.deal(players, amount);
        vm.prank(players);
        rafleTest.fund{value: 3 ether}("arslan");
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

    function testEmitHappening() public {
        vm.deal(players, amount);
        vm.prank(players);
        vm.expectEmit(true, true, false, false, address(rafleTest));
        emit fundersInfo(1 ether, "arslan");
        rafleTest.fund{value: 1 ether}("arslan");
    }

    function testContractStateDown() public PayUpToFive {
        vm.warp(block.timestamp+_interval+1);
        vm.roll(block.number+2);
        rafleTest.performUpkeep();

    }

}
