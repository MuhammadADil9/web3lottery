//SPDX-License-Identifier : MIT;


// Instructions

//lottery contract
//people will enter into the lottery by inserting certian amount into it.
//after certian time someone will be declared as winner automatically 

//enternace function
//selecting winner function

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
    struct public participant {
        uint256 amount;
        address payable userAddress;
    }
    participant[] public payable participants;
    
    
    /*Functions*/
    constructor(){
        i_owner = msg.sender;
    }

    function enterRafle() payable external {
        participants.push(publicparticipant({
            amount : msg.value,
            userAddress : msg.sender
        }));
    }

    function selectWinner() public {

    }

    public getUser(uint256 counter) public view return( address user , uint256 amount){
        (user,amount) = participants[counter];
         return (user,amount);
    }




}
