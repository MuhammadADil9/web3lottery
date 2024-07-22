//SPDX License-Identifier:MIT;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract helperConfig is Script {
    VRFCoordinatorV2Mock private vrfcordinatorAnvil;

    struct params {
        uint256 _interval;
        bytes32 gasLanePrice;
        uint64 s_subscriptionId;
        address vrfCordinaor;
        uint32 cb_gasLimit;
    }

    function sapoliaNetwork() public returns (params memory) {
        params memory temp = params({
            _interval: 300,
            gasLanePrice: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            s_subscriptionId: 0,
            vrfCordinaor: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            cb_gasLimit: 100000
        });
        return temp;
    }

    function anvilNetwork() public returns (params memory) {
        params memory temp = params({
            _interval: 300,
            gasLanePrice: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            s_subscriptionId: 0,
            vrfCordinaor: address(
                VRFCoordinatorV2Mock(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B)
            ),
            cb_gasLimit: 100000
        });
        return temp;
    }
}
