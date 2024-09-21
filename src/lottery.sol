//SPDX-License-Identifier : MIT;

/*Imports*/

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";

/* Errors */
error lottery_timeNotPassed();
error lottery_insufficientBalance();




/**
 * @author Adil
 * @notice Lottery project allowing user to enter with certian amount and giving them chance to win 
 * @dev Implementation of VRF and Keepers for randomnees and automation respectively.
 */

/*Contract*/

contract lottery is VRFConsumerBaseV2Plus{

    /*State varibales*/
    uint256 private immutable i_enteranceFee;
    address private immutable i_owner;
    uint256 private immutable i_timeLimit;
    uint256 private immutable i_lastTimeContractDeployed;

    uint256 requestId;
    bytes32 keyHash;
    uint256 subId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    uint32 numWords;
    bytes extraArgs;


    struct participant {
        uint256 amount;
        address payable userAddress;
    }

    participant[]  public participants;

    
    /*Functions*/
    constructor(address vrfCordinator) VRFConsumerBaseV2Plus(vrfCordinator) {
        i_owner = msg.sender;
        i_enteranceFee = 1 ether;
        i_timeLimit = 4000;
        i_lastTimeContractDeployed = block.timestamp;
    }

    function enterRafle() payable external {
        
        if(msg.value < i_enteranceFee){
            revert lottery_insufficientBalance();
        }
        
        participants.push(participant({
            amount : msg.value,
            userAddress : payable(msg.sender)
        }));
    }


    function selectWinner() public {
        if(block.timestamp-i_lastTimeContractDeployed < i_timeLimit){
            revert lottery_timeNotPassed();
        }

        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                   VRFV2PlusClient.ExtraArgsV1({
                       nativePayment: enableNativePayment
                   })
                )
            }));
    }





    /* Getters Functions */
    function getUser(uint256 counter) public view returns( address user , uint256 amount){
        participant memory temp = participants[counter];
        amount = temp.amount;
        user = temp.userAddress;
         return (user,amount);
    }



}
