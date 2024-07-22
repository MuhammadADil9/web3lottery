//SPDX-License-Identifier:MIT

import {rafle} from "../src/Lottery.sol";
import {Script} from "forge-std/Script.sol";

contract deploy is Script {
    rafle private rafleContract;
    function run () external returns(rafle){
    vm.startBroadcast();
    vm.stopBroadcast();

    }
}

