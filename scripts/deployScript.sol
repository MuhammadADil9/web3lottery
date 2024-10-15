//SPDX-License-Identifier : MIT
pragma solidity^0.8.9;

import {lottery} from "../src/lottery.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract deployContract is Script{

    function deployContractFunction() internal view returns(lottery){
        lottery LotteryContract = new lottery();
        return LotteryContract;
    }

    function run() external view returns(lottery){
        return deployContractFunction();
    }
}

