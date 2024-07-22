//SPDX-License-Identifier:MIT

import {rafle} from "../src/Lottery.sol";
import {Script} from "forge-std/Script.sol";
import {helperConfig} from "./helperConfig.s.sol";

contract deploy is Script {
    rafle private rafleContract;
    helperConfig private hConfig;
    uint256 _interval;
    bytes32 gasLanePrice;
    uint64 s_subscriptionId;
    address vrfCordinaor;
    uint32 cb_gasLimit;

    function run() external returns (rafle) {
        hConfig = new helperConfig();
        (
            _interval,
            gasLanePrice,
            s_subscriptionId,
            vrfCordinaor,
            cb_gasLimit
        ) = hConfig.contructor_parameters();
        vm.startBroadcast();
        rafleContract = new rafle(
            _interval,
            vrfCordinaor,
            gasLanePrice,
            s_subscriptionId,
            cb_gasLimit
        );
        vm.stopBroadcast();
    return rafleContract;
    }
}
