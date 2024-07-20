//SPDX License-Identifier:MIT
pragma solidity ^0.8.18;

/**
 * @title Lottery contract that will declare random winner at random time
 * @author Adil
 * @notice involves advanced soliditiy data types such events, VRF and etc
 */

// creation of a lottery
// let the user insert the amount in the contract
// then there will be a check that conract should not populate unless or untill before a specfied time

// constant :- something that we know by default
// immutable :- something that will not change when the contract will get deployed

contract lottery {
    //error
    error lottery_TimeLimitNotExcedeed();
    error notEnoughAmount();

    //state variables
    uint256 private constant numOfWords = 1;
    uint256 private constant blockConfirmations = 2;
    address private immutable owner;
    uint256 private immutable timeToMine;
    uint256 private immutable last_time_stamp; 
    uint256 private immutable entryfee;
    address[] private ContributorsAddressArray;
    address private immutable cordinator_Vrf;
    bytes32 private immutable keyHash;
    uint64 private immutable chainId;
    uint256 private immutable callbackGasLimit;
    uint256 private s_requestId = 0;

    //Events for storing the data on the chain
    event contributor(
        string contributorName,
        uint256 amount,
        address userAddress
    );
    
    constructor(uint256 timer, uint256 amount, address vrfCordinator, bytes32 _keyHash, uint64 _chainId, uint256 _callbackGasLimit) {
        timeToMine = timer;
        last_time_stamp = block.timestamp;
        owner = msg.sender;
        entryfee = amount;
        cordinator_Vrf = vrfCordinator;
        keyHash = _keyHash;
        chainId = _chainId;
        callbackGasLimit = _callbackGasLimit;
    }

    //Payble funcion in which contributors contribute
    function fundInContract(string memory funderName) external payable {
        if (msg.value < entryfee) {
            revert notEnoughAmount();
        } else {
            ContributorsAddressArray.push(msg.sender);
            emit contributor(funderName, msg.value, msg.sender);
        }
    }

    //function announcing the winner of the contract
    function announceLottery() private {
        if(block.timestamp - last_time_stamp < timeToMine){
            revert lottery_TimeLimitNotExcedeed();
        }

          requestId = cordinator_Vrf.requestRandomWords(
            keyHash,
            chainId,
            blockConfirmations,
            callbackGasLimit,
            numOfWords
        );
    }

    // getters

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
