//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract rafle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    //errors
    error rafle_enternance_not_allowed();
    error rafle_time_limit_not_exceeded();
    error rafle_not_enough_participants();
    error rafle_failed_to_transfer_fund();
    error rafle_insert_minimum_amount_for_entering_into_rafle();
    error rafle_checkUpKeepFailed();
    error rafle_contractStateIsNotOpen();

    //type decleration
    enum contractState {
        open,
        closed,
        inProgress
    }

    // state variables
    contractState private conState;
    address payable[] private funders;
    uint256 private immutable interval;
    bytes32 private immutable gasLanePrice;
    uint64 private immutable s_subscriptionId;
    uint256 private lastTimeOccurance;
    VRFCoordinatorV2Interface private cordinatorContract;
    uint32 private immutable cb_gasLimit;
    uint32 private constant numOfWords = 1;
    uint16 private constant blockConfirmation = 2;
    uint256 private constant min_amount = 1 ether;
    uint256 public randomNumber;
    //events
    event fundersInfo(uint256 indexed amount, string indexed name);
    event winnerAddress(address indexed winner);
    event randomNumberEvent(uint256 indexedNumber);

    
    //functions
    constructor(
        uint256 _interval,
        address _cordinator,
        bytes32 _gasLanePrice,
        uint64 _s_subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(_cordinator) {
        interval = _interval;
        conState = contractState.open;
        lastTimeOccurance = block.timestamp;
        cordinatorContract = VRFCoordinatorV2Interface(_cordinator);
        gasLanePrice = _gasLanePrice;
        s_subscriptionId = _s_subscriptionId;
        cb_gasLimit = callbackGasLimit;
        randomNumber = 0;
    }

    //function for funding the contract;
    //Following CEI methodology

    function fund(string memory name) external payable {
        if (msg.value < min_amount) {
            revert rafle_insert_minimum_amount_for_entering_into_rafle();
        }

        if (conState != contractState.open) {
            revert rafle_enternance_not_allowed();
        }

        funders.push(payable(msg.sender));
        emit fundersInfo(msg.value, name);
    }

    //condition that will make sure when to or when not to trigger the contract.
    //This will further call perform up keep to make sure everything goes smoothly.
    // Enough time limit should be there.
    // player must be in the contract or there must be enough balance
    // lottery state should be open but not closed.

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool enoughTimeLimit = (block.timestamp - lastTimeOccurance >=
            interval);
        if (!enoughTimeLimit) {
            revert rafle_time_limit_not_exceeded();
        }
        
        bool enoughPlayers = (funders.length >= 5);

        if(!enoughPlayers){
            revert rafle_not_enough_participants();
        }

        uint256 conStatus = uint256(conState);
        bool contractCurrentState = (conStatus == 0);
        if(!contractCurrentState){
            revert rafle_contractStateIsNotOpen();
        }

        upkeepNeeded = (enoughTimeLimit &&
            enoughPlayers &&
            contractCurrentState);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes memory /* performData */) external override {
        conState = contractState.inProgress;
        //first of all we will have to get a random number
        uint256 request = cordinatorContract.requestRandomWords(
            gasLanePrice,
            s_subscriptionId,
            blockConfirmation,
            cb_gasLimit,
            numOfWords
        );
        emit randomNumberEvent(uint256(request));
        randomNumber = request;
        // Reuest has been sent to VRF cordinator
    }

    //CEI
    // function selectWinner() external {}

    //then we will select the winner

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 length = funders.length;
        uint256 s_randomWords = (randomWords[0] % length);
        address winner = funders[s_randomWords];

        funders = new address payable[](0);
        conState = contractState.open;
        lastTimeOccurance = block.timestamp;

        uint256 profit = funders.length;
        uint256 balance = address(this).balance - profit;

        (bool success, ) = winner.call{value: balance}("");
        if (!success) {
            revert rafle_failed_to_transfer_fund();
        }
        emit winnerAddress(winner);
    }

    function getState() public view returns (contractState) {
        return conState;
    }

    function getFundersLenth() public view returns (uint256) {
        return funders.length;
    }

    function turnOfState() external {
        conState = contractState.inProgress;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
