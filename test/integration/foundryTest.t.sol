//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {deployScript} from "../../script/deployRafle.s.sol";
import {rafleCotnract} from "../../src/rafle.sol";
import {Test, console} from "forge-std/Test.sol";
import {NetworkConfiguration} from "../../script/networkConfiguration.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

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
        console.log("this is test contract address :- ", address(this));
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
                 BALANCE ISN'T PRESENT BUT STATE IS open
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
        emit rafleCotnract.Rafle_userEntered(bilal, "pakistan");
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

    /*//////////////////////////////////////////////////////////////
         Check up keep returns true when every condition is met 
    //////////////////////////////////////////////////////////////*/

    function test_checkUpKeep() public UptoFivePersionIntoContract {
        //conditions for the checkupkeep to be performed
        // enough time should be passed                         Done
        // more than 5 people should be in the contract         Done
        // state of the contract should be opened               Done

        //arrange
        vm.warp(block.timestamp + timeLimit + 1);

        //act
        (bool checks, ) = testRafleContract.checkUpkeep("");

        //asert
        assert(checks);
    }

    /*//////////////////////////////////////////////////////////////
         Check up keep returns false when conditions aren't met 
    //////////////////////////////////////////////////////////////*/

    function test_checkUpKeepFailsIfTimeLimitDoesNotExceed()
        public
        UptoFivePersionIntoContract
    {
        //conditions for the checkupkeep to be performed
        // enough time should be passed                         Failed
        // more than 5 people should be in the contract         Done
        // state of the contract should be opened               Done

        //arrange
        // fails if the time limit does not match
        vm.warp(block.timestamp + timeLimit);

        //act
        (bool checks, ) = testRafleContract.checkUpkeep("");

        //asert
        assert(!checks);
    }

    /*//////////////////////////////////////////////////////////////
         Check up keep returns false when conditions aren't met 
    //////////////////////////////////////////////////////////////*/

    function test_checkUpKeepFailsIfPeopleDoesNotExceed()
        public
        UptoFourPersionIntoContract
    {
        //conditions for the checkupkeep to be performed
        // enough time should be passed                         Done
        // more than 5 people should be in the contract         Failed
        // state of the contract should be opened               Done

        //arrange
        // fails if the time limit does not match
        vm.warp(block.timestamp + timeLimit + 1);

        //act
        (bool checks, ) = testRafleContract.checkUpkeep("");

        //asert
        assert(!checks);
    }

    /*//////////////////////////////////////////////////////////////
         Check up keep returns false when conditions aren't met 
    //////////////////////////////////////////////////////////////*/

    function test_checkUpKeepFailsIfStateIsNotOpened()
        public
        UptoFivePersionIntoContract
    {
        //conditions for the checkupkeep to be performed
        // enough time should be passed                         Done
        // more than 5 people should be in the contract         Done
        // state of the contract should be opened               Failed

        //arrange
        // fails if the time limit does not match
        vm.warp(block.timestamp + timeLimit + 1);
        testRafleContract.closeRafle();
        //act
        (bool checks, ) = testRafleContract.checkUpkeep("");

        //asert
        assert(!checks);
    }

    /*////////////////////////////////////////////////////////////////////////////
                        Perform up keeps run well 
    ////////////////////////////////////////////////////////////////////////////*/

    function test_performUpKeepGoesWell()
        public
        UptoFivePersionIntoContract
    {
        
        // test up keep should return when 3 of the conditions are met properly.

        //arrange
        vm.warp(block.timestamp + timeLimit + 1);
        
        //act && assert
        testRafleContract.performUpkeep("");
        
    }

    /*//////////////////////////////////////////////////////////////
         Perform up keep should fail because check up keep fails 
    //////////////////////////////////////////////////////////////*/

    function test_performUpKeepFails()
        public
        UptoFivePersionIntoContract
    {
        
        // should fail because checkup keep will return false as enough time won't pass.

        //arrange
        vm.warp(block.timestamp + timeLimit);        

        //act & asert
        vm.expectRevert(rafleCotnract.Rafle_invalidPerformUpkeep.selector);
        testRafleContract.performUpkeep("");
        //expecting a revert 
    }




    /*//////////////////////////////////////////////////////////////
         TESTING ID IS NOT NULL 
    //////////////////////////////////////////////////////////////*/


    function test_WhatIsTestId() UptoFivePersionIntoContract public {
        //listen for the event when getRandomNumber method is called
        //meet the criteria for getting it called that is getting at least 5 users, time passed & state must be opened

        // arrange 
        vm.warp(block.timestamp + timeLimit + 1);
        vm.recordLogs();

        //act
        testRafleContract.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        //assert
        //we are getting two logs one from the cordinator and one that we are emitting ourselves
        assertEq(entries.length,2);
        //everything that we receive as the result of event array we usually decode it 
        uint256 ranNumber = uint256(entries[1].topics[1]);
        assertEq(entries[1].topics[0], keccak256("Rafle_RandomId(uint256)"));
        //console log number is one
        console.log(ranNumber);
        //make sure that the number we are reciving is not equvalent to zero meaning we are getting to receivie something
        assert(ranNumber != 0);

    }


    
    /*///////////////////////////////////////////////////////////////////////////
    Person isn't able to enter into the ragle when perform up keep is triggered 
    ////////////////////////////////////////////////////////////////////////////*/


    function test_PersonShouldNotEnterIntoTheRafleIfPerformUpKeepIsTriggered() public UptoFivePersionIntoContract {
        //make sure the conditions are met for triggering the contract
        //trigger the perform up keep
        //then make sure person should not be able to enter in the rafle 

        //Arrange
        vm.warp(block.timestamp + timeLimit + 1);
        vm.recordLogs();
        testRafleContract.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();

        //Act 
        vm.expectRevert(rafleCotnract.Rafle_contractStateNotOpened.selector);
        vm.deal(bilal,1 ether);
        vm.prank(bilal);
        testRafleContract.enterRafle{value:entranceFee}("bilal","pakistan");
        

        //assert 
        assert(entries.length == 2);

    }
    
    function test_fulfilRandomWordsFailIfCalledMaliciously() public {
        
        // If someone maliciously call the fulfilrandom words at the back it should revert with a error

        //Arrange 
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        
        //Act & Assert 
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0,address(testRafleContract));
        
    }

    // check for the constructor code









    /** Modifiers */
    modifier PersonHasBalance() {
        vm.deal(bilal, entranceFee);
        vm.prank(bilal);
        _;
    }

    modifier UptoFourPersionIntoContract() {
        for (uint256 a = 1; a <= 4; a++) {
            string memory integerConvertedToString = vm.toString(a);
            address addr = makeAddr(integerConvertedToString); // Generate a deterministic address
            vm.deal(addr, entranceFee); // Assign balance to the address
            vm.startPrank(addr); // Start prank for the address
            testRafleContract.enterRafle{value: entranceFee}("abc", "pakistan"); // Enter the raffle
            vm.stopPrank(); // Stop prank
        }
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
