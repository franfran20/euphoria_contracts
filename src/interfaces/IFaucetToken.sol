// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

interface IFaucetToken {
    function mint(address _recipient, uint256 _amount) external;
}
