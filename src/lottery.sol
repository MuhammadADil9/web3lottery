//SPDX-License-Identifier : MIT;

/* Errors */
error lottery_timeNotPassed();
error lottery_insufficientBalance();




/**
 * @author Adil
 * @notice Lottery project allowing user to enter with certian amount and giving them chance to win 
 * @dev Implementation of VRF and Keepers for randomnees and automation respectively.
 */

/*Contract*/

contract lottery{

    /*State varibales*/
    uint256 private immutable i_enteranceFee;
    address private immutable i_owner;
    uint256 private immutable i_timeLimit;
    uint256 private immutable i_lastTimeContractDeployed;

    struct participant {
        uint256 amount;
        address payable userAddress;
    }

    participant[]  public participants;

    
    /*Functions*/
    constructor(){
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
    }
    
    /* Getters Functions */
    function getUser(uint256 counter) public view returns( address user , uint256 amount){
        participant memory temp = participants[counter];
        amount = temp.amount;
        user = temp.userAddress;
         return (user,amount);
    }



}
