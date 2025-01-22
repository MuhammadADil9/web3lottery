//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

//net spac for making the contract more beautiful
/**
 * @title Lottery contract
 * @author Adil
 * @dev oracle, RNG & chainlink automation
 * @notice This is a lottery smart contract. Join us and receive a chance of winning handsome amount of mon
 */

contract rafleCotnract is VRFConsumerBaseV2Plus {
    /**State variables */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_timeLimit;
    uint256 private immutable i_lastTimeContractInitiated;
    userData[] internal s_userArray;
    contractStatus private s_ContractStatus;

    //VRF request parameters
    uint256 private immutable i_subscriptionId;
    address private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint32 private constant CALLBACKGASLIMIT = 5000;
    uint16 private constant REQUEST_CONFIRMATION = 2;
    uint32 private constant NUM_OF_WORDS = 1;
    uint256 private s_requestId = 0;
    /**Functions */
    constructor(
        uint256 _entranceFee,
        uint256 _timeLimit,
        uint256 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_timeLimit = _timeLimit;
        i_lastTimeContractInitiated = block.timestamp;
        _subscriptionId = _subscriptionId;
        i_vrfCoordinator = _vrfCoordinator;
        _keyHash = _keyHash;
        s_ContractStatus = contractStatus.open;
    }

    function enterRafle(
        string memory _name,
        string memory _country
    ) public payable {
        if (msg.value < 1 ether) {
            revert Rafle_insufficientEntranceFee(msg.value, 1 ether);
        }
        if (uint(s_ContractStatus) != 0) {
            revert Rafle_contractStateNotOpened();
        }
        s_userArray.push(
            userData({
                name: _name,
                country: _country,
                userAddress: payable(msg.sender)
            })
        );
        emit userEntered(msg.sender, _country);
    }

    function selectWinner() public {
        //allowing people to win the rafle
        if ((block.timestamp - i_lastTimeContractInitiated) < i_timeLimit) {
            revert Rafle_notEnoughTimePassed();
        }
        if (s_userArray.length < 5) {
            revert Rafle_notEnoughPeopleInTheContract();
        }

        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: CALLBACKGASLIMIT,
                numWords: NUM_OF_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        // emitting a event that a event is initiated
        emit lotteryInitiated();
        
        //closing the lottery becuase once inititaed it will only open when winner is selected and everything is done
         s_ContractStatus = contractStatus.open;

    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords 
    ) internal override {}

    /**Getters */
    function getEntranceAmount() private view returns (uint256) {
        return i_entranceFee;
    }

    /**Function Modifiers */

    /**Events */
    event userEntered(address indxed, string indexed);
    event lotteryInitiated();
    /**Errors */

    error Rafle_insufficientEntranceFee(uint256 sender, uint256 required);
    //Error or not enough time has passed
    error Rafle_notEnoughTimePassed();
    //contract state is not opened
    error Rafle_contractStateNotOpened();
    //not enough people in the contract
    error Rafle_notEnoughPeopleInTheContract();

    /**Struct Types */
    struct userData {
        string name;
        string country;
        address payable userAddress;
    }
    /**Enums*/
    enum contractStatus {
        open,
        pending,
        closed
    }
}


// There has to be the automation for triggering the winner function
// there has to be a random number that will select the winner

// Previous Contract




// contract raffle is VRFConsumerBaseV2Plus {
//     /** State Variables */

//     uint256 private immutable i_EnteranceFee;
//     address private immutable i_Owner;

//     // variables required for VRF
//     uint256 s_subscriptionId;
//     address vrfCoordinator;
//     bytes32 s_keyHash;
//     uint32 private constant CALLBACKGASLIMIT = 5000;
//     uint16 private constant REQUESTCONFIRMATION = 2;
//     uint32 private constant NUMOFWORDS = 1;

//     // instance for link token contract
//     LinkTokenInterface linkToken;

//     // array of structure;
//     user[] public s_users;
//     //time variable
//     uint256 private immutable i_timeLimit;
//     uint256 private LotterylastTime;
//     uint256 private requestId;

//     RafleState private rafle_State_Instance;

//     /** Functions */
//     constructor(
//         uint256 fee,
//         uint256 time,
//         uint256 subId,
//         bytes32 keyHash,
//         address vrfCordinatorAddress,
//         address linkTokenContract
//     ) VRFConsumerBaseV2Plus(vrfCordinatorAddress) {
//         i_EnteranceFee = fee;
//         i_Owner = msg.sender;
//         i_timeLimit = time;
//         LotterylastTime = block.timestamp;
//         s_subscriptionId = subId;
//         s_keyHash = keyHash;
//         vrfCoordinator = vrfCordinatorAddress;
//         s_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCordinatorAddress);
//         linkToken = LinkTokenInterface(linkTokenContract);

//         // running the function for creating the subscription programmatically
//         _createNewSubscription();

//         // initializing the rafle state using the enum
//         rafle_State_Instance = RafleState.open;
//     }

//     function enterRafle(string calldata name) external payable {
//         if (msg.value < i_EnteranceFee) {
//             revert rafle_insufficientBalance(
//                 "Insufficient Balance, required balance is :- ",
//                 i_EnteranceFee
//             );
//         }
//         if(rafle_State_Instance != RafleState.open ){
//             revert rafle_rafleState();
//         }

//         // inserting the users by inserting appropriate arguments
//         s_users.push(user(payable(msg.sender), name, block.timestamp));
//         emit updateParticipants(name, msg.sender);
//     }

//     function runLottery() external {
//         // checking if not enough time has passed

//         if (block.timestamp - LotterylastTime < i_timeLimit) {
//             revert rafle_notEnoughTimePassed();
//         }
//         // reverting with a error if there are less than 5 people within the array
//         if (s_users.length < 5) {
//             revert rafle_notEnoughPersonInLottery();
//         }
//         rafle_State_Instance = RafleState.close;

//         VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
//                 keyHash: s_keyHash,
//                 subId: s_subscriptionId,
//                 requestConfirmations: REQUESTCONFIRMATION,
//                 callbackGasLimit: CALLBACKGASLIMIT,
//                 numWords: NUMOFWORDS,
//                 // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
//                 extraArgs: VRFV2PlusClient._argsToBytes(
//                     VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
//                 )
//             });

//         // requesting random word
//         requestId = s_vrfCoordinator.requestRandomWords(request);
//     }

//     function fulfillRandomWords(
//         uint256 /*requestId */,
//         uint256[] calldata randomWords
//     ) internal override {
//         // No checks
//         // Effects
//         uint256 number = randomWords[0];
//         number = s_users.length % number;
//         // user memory temp =
//         address winner = s_users[number].participant;
//         uint256 balance = address(this).balance;
//         uint256 winnerAmount = balance - 2.5 ether;
//         //transfering the amount the winner
//         (bool sucess, ) = winner.call{value: winnerAmount}("");
//         if (!sucess) {
//             revert rafle_amountNotSentToWinner();
//         }
//         emit amountPaidToWinner(winner, s_users[number].name);
//         LotterylastTime = block.timestamp;
//         delete s_users;

//         //open the rafle state once everything is done
//         rafle_State_Instance = RafleState.open;
//     }

//     // Create a new subscription when the contract is initially deployed.
//     function _createNewSubscription() private Owner {
//         s_subscriptionId = s_vrfCoordinator.createSubscription();
//         // Add this contract as a consumer of its own subscription.
//         s_vrfCoordinator.addConsumer(s_subscriptionId, address(this));
//     }

//     //function for funding the subscription
//     function topUpSubscription(uint256 amount) external Owner {
//         linkToken.transferAndCall(
//             address(s_vrfCoordinator),
//             amount,
//             abi.encode(s_subscriptionId)
//         );
//     }

//     //function to withdraw the funds from the contract
//     function withdraw(uint256 amount, address to) external Owner {
//         linkToken.transfer(to, amount);
//     }

//     /** Functions Modifiers */
//     modifier Owner() {
//         if (msg.sender != i_Owner) {
//             revert rafle_notOwner();
//         }
//         _;
//     }

//     /** Events */
//     event updateParticipants(string indexed name, address indexed userAddress);
//     event amountPaidToWinner(
//         address indexed winnerAddress,
//         string indexed winnerName
//     );

//     /** Errors */
//     error rafle_insufficientBalance(string reason, uint256 requiredAmount);
//     error rafle_notEnoughTimePassed();
//     error rafle_notEnoughPersonInLottery();
//     error rafle_amountNotSentToWinner();
//     error rafle_notOwner();
//     error rafle_rafleState();

//     /** Struct */
//     struct user {
//         address payable participant;
//         string name;
//         uint256 time;
//     }

//     /** Enums */

//     enum RafleState {open,close}

// }
