//SPDX License-Identifier:MIT;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract helperConfig is Script {
    struct constructorParameters {
        uint256 _interval;
        bytes32 gasLanePrice;
        uint64 s_subscriptionId;
        address vrfCordinaor;
        uint32 cb_gasLimit;
        address linkTokensAddress;
    }

    constructorParameters public contructor_parameters;

    constructor() {
        if (block.chainid == 11155111) {
            contructor_parameters = sapoliaNetwork();
        } else {
            contructor_parameters = anvilNetwork();
        }
    }

    function sapoliaNetwork()
        public
        pure
        returns (constructorParameters memory)
    {
        return
            constructorParameters({
                _interval: 200,
                gasLanePrice: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                s_subscriptionId: 0,
                vrfCordinaor: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                cb_gasLimit: 50000,
                linkTokensAddress : 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function anvilNetwork() public returns (constructorParameters memory) {
        if (contructor_parameters.vrfCordinaor != address(0)) {
            return contructor_parameters;
        }

        uint96 fee = 0.25 ether;
        uint96 gasPrice = 1e8;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfcordinatorAnvil = new VRFCoordinatorV2Mock(
            fee,
            gasPrice
        );
        vm.stopBroadcast();

        return
            constructorParameters({
                _interval: 200,
                gasLanePrice: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                s_subscriptionId: 0,
                vrfCordinaor: address(vrfcordinatorAnvil),
                cb_gasLimit: 500000,
                linkTokensAddress : 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }
}
