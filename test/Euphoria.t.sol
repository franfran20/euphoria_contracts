// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {EuphoriaBookFactory} from "../src/EuphoriaBookFactory.sol";
import {MockUSDC} from "../src/test/MockUSDC.sol";
import {DeployEuphoria} from "../script/DeployEuphoria.s.sol";

contract EuphoriaBookTest is Test {
    EuphoriaBookFactory euphoria;
    MockUSDC mockUSDC;
    DeployEuphoria deployEuphoria;

    address owner = makeAddr("owner");

    function setUp() public {
        vm.startPrank(owner);

        deployEuphoria = new DeployEuphoria();
        (address mockUSDCAddr, address euphoriaAddr) = deployEuphoria.deployEuprohia();
        euphoria = EuphoriaBookFactory(euphoriaAddr);
        mockUSDC = MockUSDC(mockUSDCAddr);
        vm.stopPrank();
    }

    function testDeployedSuccesfully() public view {
        (, uint256 seasonId,) = euphoria.getCurrentSeason();
        assertEq(seasonId, 1);
    }
}
