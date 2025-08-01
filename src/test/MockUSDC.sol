// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IFaucetToken} from "../interfaces/IFaucetToken.sol";

contract MockUSDC is ERC20, IFaucetToken {
    constructor() ERC20("Mock USDC", "mUSDC") {}

    function mint(address _recipient, uint256 _amount) external {
        _mint(_recipient, _amount);
    }

    function decimals() public view override returns (uint8) {
        return 6;
    }
}
