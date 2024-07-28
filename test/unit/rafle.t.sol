//SPDX-License-Identifier : MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {deploy} from "../../script/deploy.s.sol";
import {rafle} from "../../src/Lottery.sol";
import {helperConfig} from "../../script/helperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {acceptor} from "./acceptorContract.sol";

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
    acceptor public acp;

    modifier PayUpToFive() {
        address one = makeAddr("one");
        address two = makeAddr("two");
        address three = makeAddr("three");
        address four = makeAddr("four");
        address five = makeAddr("five");

        vm.deal(one, 5 ether);
        vm.deal(two, 5 ether);
        vm.deal(three, 5 ether);
        vm.deal(four, 5 ether);
        vm.deal(five, 5 ether);

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
        acp = new acceptor();
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



    // perform has to work because checkup conditions are all satisfied
    function testReturnRandomWords() public PayUpToFive {
        vm.warp(block.timestamp + _interval + 2);
        vm.roll(block.number + 4);
        rafleTest.performUpkeep("");
    }

    //checking for logs in performUpKeep

    function testReturnRandomWordsLogs() public PayUpToFive {
        vm.warp(block.timestamp + _interval + 2);
        vm.roll(block.number + 4);

        vm.recordLogs();
        rafleTest.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        
        bytes32 data = logs[1].topics[0];

        //type casting bytes into uint256
        console.log(uint256(data));
        assert(uint256(data) > 0);
        assert(rafleTest.randomNumber() != 0);
    } 

    // Random words will fail because performup keep is not called
    //Fuzz tests, where foudnary gets the input and does the rest of stuff
    function testRandomWordsShouldFail(uint256 _id) public {
        vm.expectRevert();
        VRFCoordinatorV2Mock(vrfCordinaor).fulfillRandomWords(_id,address(rafleTest));
    }
    
    // Massive test < Beginning to End >


function testCompleteSmartContract() public PayUpToFive {

    uint256 calculation = 5*5-5;
    uint256 prize = calculation * 1 ether;
    console.log("Expected Prize");
    console.log(prize);

    //state of the smart contract should be open 
    uint256 stateOfSmartContract = uint256(rafleTest.getState());
    assert(stateOfSmartContract == 0);

    // //balance of the contract should be zero intially (remove payUpToFive)
    // assertEq(rafleTest.getContractBalance(),0);
    // }

    //Balance of the winner should be equalvant to zero
    assertEq(rafleTest.getWinnerBalanc(), 0);

    //balance of the contract should not be zero as soon as people participates in it.
    assert(rafleTest.getContractBalance() == 25 ether);

    //moving the timestamp forward to make the [ checkupkeep ] true
    vm.warp(block.timestamp+_interval+2);


    // calling perform up keep
    rafleTest.performUpkeep("");

    //Balance that will transferred after deucting the lottery fee/profit
    // console.log("Balance to transfer");
    // console.log(rafleTest.balance());



    //balance of the contract
    // console.log("Contract Balance");
    // console.log(rafleTest.getContractBalance());

    // calling the fulfill random function on the behalf of the vrf cordinator
    VRFCoordinatorV2Mock(vrfCordinaor).fulfillRandomWords(rafleTest.randomNumber(),address(rafleTest));


    // console.log("Winner Balance");
    // console.log(rafleTest.getWinnerBalanc());
    // Balance of the winner should be equalant to prize

    assert(rafleTest.getWinnerBalanc() == prize);
    assert(rafleTest.getFundersLenth() == 0);

    }
}