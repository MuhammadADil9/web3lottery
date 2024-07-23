//SPDX-License-Identifier:MIT

import {rafle} from "../src/Lottery.sol";
import {Script} from "forge-std/Script.sol";
import {helperConfig} from "./helperConfig.s.sol";
import {interaction} from "./Interaction.s.sol";

contract deploy is Script {
    rafle private rafleContract;
    helperConfig private hConfig;

    function run() external returns (rafle, helperConfig) {
        hConfig = new helperConfig();
        (
            uint256 _interval,
            bytes32 gasLanePrice,
            uint64 s_subscriptionId,
            address vrfCordinaor,
            uint32 cb_gasLimit
        ) = hConfig.contructor_parameters();

        if(s_subscriptionId == 0){
        interaction  getChainID = new interaction();
        s_subscriptionId = getChainID.getSubscription();
        }

        vm.startBroadcast();
        rafleContract = new rafle(
            _interval,
            vrfCordinaor,
            gasLanePrice,
            s_subscriptionId,
            cb_gasLimit
        );
        
        vm.stopBroadcast();
        return (rafleContract,hConfig);
    }
}
