//SPDX-License-Identifier : MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {deploy} from "../script/deploy.s.sol";
import {rafle} from "../src/Lottery.sol";

contract test is Test {
    
    rafle public rafleTest;
    deploy public deployTest;
    address public players = vm.addr(1);
    uint256 public amount = 5 ether;


    function setUp() public {
        rafleTest = new deploy();
    }


    
}
