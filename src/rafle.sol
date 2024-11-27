// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//net spac for making the contract more beautiful
/**
 * @title Lottery contract
 * @author Adil
 * @dev oracle, RNG & chainlink automation
 * @notice This is a lottery smart contract. Join us and receive a chance of winning handsome amount of mon
 */

//pragma > versioning > imports > comments

// functions for entering into the contract
// functions for winning the lottery

// errors
// error if the participant fails to submit sufficient amount of money in the contract

contract raffle {
    /** State Variables */

    uint256 private immutable i_EnteranceFee;
    address private immutable i_Owner;
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

    
    
    /** Functions */
    constructor(uint256 fee, uint256 time) {
        i_EnteranceFee = fee;
        i_Owner = msg.sender;
        i_timeLimit = time;
        LotterylastTime = block.timestamp;
    }

    function enterRafle(string calldata name) public payable {
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

    function winningRafle() public {
        //logic
    }

    
    
    /** Events */
    event updateParticipants(string indexed name, address indexed userAddress);

    
    /** Errors */
    error rafle_insufficientBalance(string reason, uint256 requiredAmount);
    error rafle_notEnoughTimePassed();
}
