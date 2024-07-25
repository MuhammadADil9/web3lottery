// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@solmate/tokens/ERC20.sol";

interface ERC677Receiver {
    function onTokenTransfer(
        address _sender,
        uint _value,
        bytes memory _data
    ) external;
}

contract LinkToken is ERC20 {
    uint256 constant INITIAL_SUPPLY = 1000000000 * 10**18;
    uint8 constant DECIMALS = 18;

    constructor() ERC20("LinkToken", "LINK", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes _data
    );

    function transferAndCall(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public returns (bool success) {
        emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    function contractFallback(
        address _to,
        uint256 _value,
        bytes memory _data
    ) private {
        ERC677Receiver receiver = ERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}
