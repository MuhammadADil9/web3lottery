// SPDX-License-Identifier: MIT

/* Imports */
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

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
    enum LotteryState{open,close}

    /* State variables */
    uint256 private immutable i_enteranceFee;
    address private immutable i_owner;
    uint256 private immutable i_timeLimit;
    uint256 private immutable i_lastTimeLotteryStarted;
    address private winnerAddress;             
    LotteryState private s_state = LotteryState.open;

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
    }


    /* Function to enter the lottery */
    function enterRafle() external payable {
        if(uint(s_state)!=0){
            revert lottery_enteranceNotAllowed();
        }

        if (msg.value < i_enteranceFee) {
            revert lottery_insufficientBalance();
        }
        participants.push(
            participant({amount: msg.value, userAddress: payable(msg.sender)})
        );
    }

    /* Function to select the winner */
    function selectWinner() external {
        if (block.timestamp - i_lastTimeLotteryStarted < i_timeLimit) {
            revert lottery_timeNotPassed();
        }
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
        //got the random word
        uint randomWord = randomWords[0] % participants.length;
        //created a struct instance for fetching the address of winner at specified index within the array
        participant memory temp = participants[randomWord];
        //stored winner address
        winnerAddress = temp.userAddress;
        //transfering the amount to the winner
        (bool ifSent,) = winnerAddress.call{value:address(this).balance}("");
        if(!ifSent){
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
}

// what should be done after selecting the winner ?
// winner address should be stored                  Done
// time to be noted                                 Done
// cash will be transfered to the winner            Done


// create a enum 
// enum is used to track the state of an object/process
// useful datatype with multiple options       
//------
// declaring a datatype that is of enum                                                     Done
// initally set equavalent to open                                                          Done
// as soon  as random number is getting picked up it wil change itself into close           Done
// check to be implemented in the lottery joining function                                  Done
// finally when the winner get selected it will change itself back to original state        Done