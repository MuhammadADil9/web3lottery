//SPDX-License-Identifier : MIT
pragma solidity^0.8.9;

import {lottery} from "../src/lottery.sol";

contract deployContract{

    function deployContractFunction() internal view returns(lottery){
        lottery LotteryContract = new lottery();
        return LotteryContract;
    }

    function run() external view returns(lottery){
        return deployContractFunction();
    }
}

