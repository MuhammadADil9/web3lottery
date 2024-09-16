//SPDX-License-Identifier:MIT

import {rafle} from "../src/Lottery.sol";
import {Script, console} from "forge-std/Script.sol";
import {helperConfig} from "./helperConfig.s.sol";
import {createSubscription, fundSubscription, addConsumer} from "./Interaction.s.sol";
import {LinkToken} from "../test/mocks/linktoken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {rafle} from "../src/Lottery.sol";

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
            uint32 cb_gasLimit,
            address linkTokensAddress,
            uint256 key
        ) = hConfig.contructor_parameters();

        if (s_subscriptionId == 0) {
            createSubscription subcriptionCreationContract = new createSubscription();
            s_subscriptionId = subcriptionCreationContract.creatSubscription(
                vrfCordinaor,
                key
            );
        }
        //Now Its time to fund the subscription ID
        //Eveb a ID that is created online/UI can be funded programmatiaclly
        fundSubscription subscribFund = new fundSubscription();
        subscribFund.fundingSubscription(
            s_subscriptionId,
            vrfCordinaor,
            linkTokensAddress,
            key
        );

        vm.startBroadcast();
        rafleContract = new rafle(
            _interval,
            vrfCordinaor,
            gasLanePrice,
            s_subscriptionId,
            cb_gasLimit
        );
        vm.stopBroadcast();
        addConsumer _addConsumer = new addConsumer();
        _addConsumer.addConsumerFinal(
            vrfCordinaor,
            s_subscriptionId,
            address(rafleContract),
            key
        );

        return (rafleContract, hConfig);
    }
}
