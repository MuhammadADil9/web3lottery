//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract rafle is VRFConsumerBaseV2,AutomationCompatibleInterface {
    error rafle_enternance_not_allowed();
    error rafle_time_limit_not_exceeded();
    error rafle_not_enough_participants();
    error rafle_failed_to_transfer_fund();

    address payable[] private funders;
    event fundersInfo(uint256 indexed amount, string name);

    enum contractState {
        open,
        closed,
        inProgress
    }

    uint256 private immutable interval;
    contractState private conState;
    uint256 private lastTimeOccurance;
    VRFCoordinatorV2Interface private cordinatorContract;
    bytes32 private immutable gasLanePrice;
    uint64 private immutable s_subscriptionId;
    uint32 private immutable fb_gasLimit;
    uint32 private constant numOfWords = 1;
    uint16 private constant blockConfirmation = 2;

    constructor(
        uint256 _interval,
        address _cordinator,
        bytes32 _gasLanePrice,
        uint64 _s_subscriptionId
    ) VRFConsumerBaseV2(_cordinator) {
        interval = _interval;
        conState = contractState.open;
        lastTimeOccurance = block.timestamp;
        cordinatorContract = VRFCoordinatorV2Interface(_cordinator);
        gasLanePrice = _gasLanePrice;
        s_subscriptionId = _s_subscriptionId;
    }

    //function for funding the contract;
    //Following CEI methodology
    function fund(string memory name) external payable {
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
    bytes calldata /* checkData */
)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory /* performData */)
{
    bool enoughTimeLimit = (block.timestamp - lastTimeOccurance >= interval);
    bool enoughPlayers = (funders.length >= 5);
    uint256 conStatus = uint256(conState);
    bool contractNotInProgress = (conStatus == 0);

    upkeepNeeded = (enoughTimeLimit && enoughPlayers && contractNotInProgress);
    return (upkeepNeeded, "");
}

    function performUpkeep(bytes calldata /* performData */) external override {
        conState = contractState.inProgress;
        //first of all we will have to get a random number
        uint256 s_requestId = cordinatorContract.requestRandomWords(
            gasLanePrice,
            s_subscriptionId,
            blockConfirmation,
            fb_gasLimit,
            numOfWords
        );

        // Reuest has been sent to VRF cordinator
    }

    //CEI
    function selectWinner() external {}

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

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert rafle_failed_to_transfer_fund();
        }
    }
}
