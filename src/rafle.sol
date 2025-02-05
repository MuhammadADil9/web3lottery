//SPDX-License-Identifier:MIT
pragma solidity ^0.8.22;

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
    uint256 private lastTimeContractInitiated;
    userData[] internal s_userArray;
    contractStatus private s_ContractStatus;
    address payable private winner;

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
        lastTimeContractInitiated = block.timestamp;
        i_subscriptionId = _subscriptionId;
        i_vrfCoordinator = _vrfCoordinator;
        i_keyHash = _keyHash;
        s_ContractStatus = contractStatus.open;
    }

    function enterRafle(
        string memory _name,
        string memory _country
    ) public payable {
        //checks

        if (msg.value < i_entranceFee) {
            revert Rafle_insufficientEntranceFee(msg.value, 1 ether);
        }
        if (uint(s_ContractStatus) != 0) {
            revert Rafle_contractStateNotOpened();
        }

        // effects
        s_userArray.push(
            userData({
                name: _name,
                country: _country,
                userAddress: payable(msg.sender)
            })
        );

        //interaction

        emit userEntered(msg.sender, _country);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool time = (block.timestamp - lastTimeContractInitiated) > i_timeLimit;
        bool people = s_userArray.length >= 5;
        bool stateOpened = uint(s_ContractStatus) == 0;
        upkeepNeeded = time && people && stateOpened;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        //checks
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Rafle_invalidPerformUpkeep();
        }

        //interactions
        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: CALLBACKGASLIMIT,
                numWords: NUM_OF_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: true})
                )
            })
        );
        // emitting a event that a event is initiated
        emit lotteryInitiated();
        //effects
        //closing the lottery becuase once inititaed it will only open when winner is selected and everything is done
        s_ContractStatus = contractStatus.pending;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        //checks

        //effects
        //first of the number received will be modulos by the total number
        uint winnerIndex = randomWords[0] % s_userArray.length;
        uint256 amountToTransfer = address(this).balance -
            (s_userArray.length * 1 ether);
        winner = s_userArray[winnerIndex].userAddress;
        //transfering the amount to the winner
        (bool success, ) = winner.call{value: amountToTransfer}("");
        if (!success) {
            revert Rafle_failedToTransferMoney();
        }

        //emitting the event that winner is selected
        emit Rafle_winnerSelected();
        //resetting the array once again
        delete s_userArray;
        lastTimeContractInitiated = block.timestamp;
        // reopening the array once everything is donw
        s_ContractStatus = contractStatus.open;
    }

    function closeRafle() public {
        s_ContractStatus = contractStatus.pending;
    }

    /**Getters */
    function getEntranceAmount() public view returns (uint256) {
        return i_entranceFee;
    }

    function getState() public view returns (uint256) {
        return uint(s_ContractStatus);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserQuantity() public view returns (uint256) {
        return s_userArray.length;
    }

    /**Function Modifiers */

    /**Events */
    event userEntered(address indxed, string indexed);
    event lotteryInitiated();
    //event for declaring thw winner
    event Rafle_winnerSelected();

    /**Errors */

    error Rafle_insufficientEntranceFee(uint256 sender, uint256 required);
    //Error or not enough time has passed
    error Rafle_notEnoughTimePassed();
    //contract state is not opened
    error Rafle_contractStateNotOpened();
    //not enough people in the contract
    error Rafle_notEnoughPeopleInTheContract();
    // error in the case failed to transfer the amount the winner
    error Rafle_failedToTransferMoney();
    // invalid perform upkeep error
    error Rafle_invalidPerformUpkeep();
    /**Struct Types */
    struct userData {
        string name;
        string country;
        address payable userAddress;
    }
    /**Enums*/
    enum contractStatus {
        open,
        pending
    }
}
