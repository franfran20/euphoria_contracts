// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

import {IEuphoriaBook} from "./interfaces/IEuphoriaBook.sol";

/**
 * @notice The euphoria books are sould bound ERC721 contracts, with each chapter of the book
 *  representing an incremental token id.
 * @dev only using natspec to explain not so obvious decisions.
 */
contract EuphoriaBook is ERC721, IEuphoriaBook {
    /*   ERRORS   */
    error SoulBoundChapters();

    uint256 chapterCount;

    /**
     * @param _name euphoria book name
     * @param _symbol euphoria book symbol, short form of book name.
     */
    constructor(string memory _name, string memory _symbol, uint256 _chapterLock) ERC721(_name, _symbol) {}

    /*   OVERIDE FOR SOUL BOUND FUNCTIONS   */

    /// @inheritdoc IERC721
    function transferFrom(address, address, uint256) public pure override {
        revert SoulBoundChapters();
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert SoulBoundChapters();
    }

    /// @inheritdoc IERC721
    function approve(address, uint256) public pure override {
        revert SoulBoundChapters();
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address, bool) public pure override {
        revert SoulBoundChapters();
    }
}
