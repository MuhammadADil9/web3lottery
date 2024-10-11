// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/* Imports */

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
/* Contract for VRF functionality  */
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/* Contract for automation functinality */
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";


/* Errors */
error lottery_timeNotPassed();
error lottery_insufficientBalance();
error lottery_fundNotTransferred();
error lottery_enteranceNotAllowed();

/**
 * @author Adil
 * @notice Lottery project allowing users to enter with a certain amount and giving them a chance to win
 * @dev Implementation of VRF and Keepers for randomness and automation respectively.
 */



/* Contract */
contract lottery is VRFConsumerBaseV2Plus {
   
    /*Type Declaration*/
    enum LotteryState {
        open,
        close
    }

    /* State variables */
    uint256 private immutable i_enteranceFee;
    address private immutable i_owner;
    uint256 private immutable i_timeLimit;
    uint256 private immutable i_lastTimeLotteryStarted;
    address private winnerAddress;
    LotteryState private s_state = LotteryState.open;
    // uint256 private counter;
    /* Request Parameters */
    uint32 private immutable i_numWords;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyHash;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint256 private subId;
    

    struct participant {
        uint256 amount;
        address payable userAddress;
    }

    participant[] public participants;


    event WinnerSelected(address indexed winner);
    event EnteredLottery(address indexed participant, string indexed name, uint256 indexed amount);


    

    /* Constructor */
    constructor(
        address vrfCordinator,
        uint32 _callBackGas,
        bytes32 _keyhash,
        uint256 _subId
    ) VRFConsumerBaseV2Plus(vrfCordinator) {
        i_owner = msg.sender;
        i_enteranceFee = 1 ether;
        i_timeLimit = 4000;
        i_lastTimeLotteryStarted = block.timestamp;
        i_numWords = 1;
        i_callbackGasLimit = _callBackGas;
        i_keyHash = _keyhash;
        subId = _subId;
        // counter = 0;
    }


    /* Function to enter the lottery */
    function enterRafle(string memory name) external payable {
        //CEI Pattern

        //Checks

        if (uint(s_state) != 0) {
            revert lottery_enteranceNotAllowed();
        }

        if (msg.value < i_enteranceFee) {
            revert lottery_insufficientBalance();
        }


        // Effects
        participants.push(
            participant({amount: msg.value, userAddress: payable(msg.sender)})
        );

        // Emitting a event that user has enterted into the rafle.
        emit EnteredLottery(msg.sender,name,msg.value);


    }


    /* Function to select the winner */
    
     function checkUpkeep(
        bytes calldata /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */){
        //C E I
        if(block.timestamp - i_lastTimeLotteryStarted < i_timeLimit && participants.length < 10 && uint(s_state) != 0 ){
            upkeepNeeded = false;
        }else{
            upkeepNeeded = true;
        }

        return (upkeepNeeded,"");
    }

    
    
    function performUpkeep(bytes calldata performData) external {

        // CEI

        //Checks

        (bool upkeepNeeded,) = checkUpkeep("");

        
        // chaning the state to close
        s_state = LotteryState.close;



        // Use VRFV2PlusClient.RandomWordsRequest directly
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: subId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: i_numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    /* Function to handle the fulfillment of random words */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {

        //CEI

        //Checks    X

        //Effect
        //got the random word
        uint randomWord = randomWords[0] % participants.length;
        //created a struct instance for fetching the address of winner at specified index within the array
        participant memory temp = participants[randomWord];
        //stored winner address
        winnerAddress = temp.userAddress;
        emit WinnerSelected(winnerAddress);
        //resetting the array once a winner is selected
        participants = new participant[](0);


        //Interactions
        //transfering the amount to the winner
        (bool ifSent, ) = winnerAddress.call{value: address(this).balance}("");
        if (!ifSent) {
            revert lottery_fundNotTransferred();
        }

        s_state = LotteryState.open;
    }

    /* Getter function to retrieve participant information */
    function getUser(
        uint256 counter
    ) public view returns (address user, uint256 amount) {
        participant memory temp = participants[counter];
        amount = temp.amount;
        user = temp.userAddress;
        return (user, amount);
    }


//What are the conditions that must be checked before executing the lottery
// time limit 
// lottery state should be equivalent to open    
// the number of participants should be greater than 10
// Implemented these conditions 


//implement performupkeep
//why did we remove override along with function ?


}

