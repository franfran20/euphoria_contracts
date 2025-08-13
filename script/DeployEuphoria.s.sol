// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {EuphoriaBookFactory} from "../src/EuphoriaBookFactory.sol";
import {MockUSDC} from "../src/test/MockUSDC.sol";

import {IEuphoriaBookFactory} from "../src/interfaces/IEuphoriaBookFactory.sol";

contract DeployEuphoria is Script {
    uint256 public BOOK_CREATION_COST = 1.1e6; // 1.1 USD
    uint256 public SUBSCRIPTION_COST = 20e6; // 20 USD
    uint256 public SUBSCRIPTION_VOTES = 4; // 4 votes per subscription
    uint256 public SUBSCRIPTION_DURATION = 15 minutes; // 15 minutes
    uint256 public VOTING_DELAY = 20 minutes; // 20 minutes
    uint256 public VOTING_DURATION = 20 minutes; // 20 minutes

    function run() public {
        vm.startBroadcast();
        deployEuprohia();
        vm.stopBroadcast();
    }

    function deployEuprohia() public returns (address, address) {
        MockUSDC mockUSDC = new MockUSDC();
        IEuphoriaBookFactory.ConstructorParams memory _constructorParams = IEuphoriaBookFactory.ConstructorParams({
            token: address(mockUSDC),
            bookCreationCost: BOOK_CREATION_COST,
            subscriptionCost: SUBSCRIPTION_COST,
            subscriptionVotes: SUBSCRIPTION_VOTES,
            subscriptionDuration: SUBSCRIPTION_DURATION,
            votingDelay: VOTING_DELAY,
            votingDuration: VOTING_DURATION
        });
        EuphoriaBookFactory euphoria = new EuphoriaBookFactory(_constructorParams);

        console.log("Mock USDC Address: ", address(mockUSDC));
        console.log("Euphoria Book Factory: ", address(euphoria));

        return (address(mockUSDC), address(euphoria));
    }
}
