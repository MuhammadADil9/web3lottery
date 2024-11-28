// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

contract raffle is VRFConsumerBaseV2Plus {
    /** State Variables */

    uint256 private immutable i_EnteranceFee;
    address private immutable i_Owner;

    // variables required for VRF
    uint256 s_subscriptionId;
    address vrfCoordinator;
    bytes32 s_keyHash;
    uint32 private constant CALLBACKGASLIMIT = 5000;
    uint16 private constant REQUESTCONFIRMATION = 2;
    uint32 private constant NUMOFWORDS = 1;

    // instance for link token contract
    LinkTokenInterface linkToken;

    //struct for storing the user information
    struct user {
        address payable participant;
        string name;
        uint256 time;
    }

    // array of structure;
    user[] public s_users;
    //time variable
    uint256 private immutable i_timeLimit;
    uint256 private LotterylastTime;

    uint256 private requestId;

    /** Functions */
    constructor(
        uint256 fee,
        uint256 time,
        uint256 subId,
        bytes32 keyHash,
        address vrfCordinatorAddress,
        address linkTokenContract
    ) VRFConsumerBaseV2Plus(vrfCordinatorAddress) {
        i_EnteranceFee = fee;
        i_Owner = msg.sender;
        i_timeLimit = time;
        LotterylastTime = block.timestamp;
        s_subscriptionId = subId;
        s_keyHash = keyHash;
        vrfCoordinator = vrfCordinatorAddress;
        s_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCordinatorAddress);
        linkToken = LinkTokenInterface(linkTokenContract);

        // running the function for creating the subscription programmatically
        _createNewSubscription();
    }

    function enterRafle(string calldata name) external payable {
        if (msg.value < i_EnteranceFee) {
            revert rafle_insufficientBalance(
                "Insufficient Balance, required balance is :- ",
                i_EnteranceFee
            );
        }

        // inserting the users by inserting appropriate arguments
        s_users.push(user(payable(msg.sender), name, block.timestamp));
        emit updateParticipants(name, msg.sender);
    }

    function runLottery() external {
        // checking if not enough time has passed

        if (block.timestamp - LotterylastTime < i_timeLimit) {
            revert rafle_notEnoughTimePassed();
        }

        // reverting with a error if there are less than 5 people within the array

        if (s_users.length < 5) {
            revert rafle_notEnoughPersonInLottery();
        }


        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: REQUESTCONFIRMATION,
                callbackGasLimit: CALLBACKGASLIMIT,
                numWords: NUMOFWORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        

        // requesting random word
        requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256 /*requestId */,
        uint256[] calldata randomWords
    ) internal override {
        // No checks
        // Effects
        uint256 number = randomWords[0];
        number = s_users.length % number;
        // user memory temp =
        address winner = s_users[number].participant;
        uint256 balance = address(this).balance;
        uint256 winnerAmount = balance - 2.5 ether;
        //transfering the amount the winner
        (bool sucess, ) = winner.call{value: winnerAmount}("");
        if (!sucess) {
            revert rafle_amountNotSentToWinner();
        }
        emit amountPaidToWinner(winner, s_users[number].name);
        LotterylastTime = block.timestamp;
        delete s_users;
    }

    // Create a new subscription when the contract is initially deployed.
    function _createNewSubscription() private Owner {
        s_subscriptionId = s_vrfCoordinator.createSubscription();
        // Add this contract as a consumer of its own subscription.
        s_vrfCoordinator.addConsumer(s_subscriptionId, address(this));
    }

    //function for funding the subscription
    function topUpSubscription(uint256 amount) external Owner {
        linkToken.transferAndCall(
            address(s_vrfCoordinator),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    //function to withdraw the funds from the contract
    function withdraw(uint256 amount, address to) external Owner {
        linkToken.transfer(to, amount);
    }

    /** Functions Modifiers */
    modifier Owner() {
        if (msg.sender != i_Owner) {
            revert rafle_notOwner();
        }
        _;
    }

    /** Events */
    event updateParticipants(string indexed name, address indexed userAddress);
    event amountPaidToWinner(
        address indexed winnerAddress,
        string indexed winnerName
    );

    /** Errors */
    error rafle_insufficientBalance(string reason, uint256 requiredAmount);
    error rafle_notEnoughTimePassed();
    error rafle_notEnoughPersonInLottery();
    error rafle_amountNotSentToWinner();
    error rafle_notOwner();
}
