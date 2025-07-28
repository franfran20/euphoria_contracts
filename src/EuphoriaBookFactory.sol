// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEuphoriaBookFactory} from "./interfaces/IEuphoriaBookFactory.sol";
import {Constants} from "./libraries/Constants.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @notice the euphoria book factory containing all on chian logic for books on euphoria
 */
contract EuphoriaBookFactory is IEuphoriaBookFactory {
    // modifier for checking deadlin for sig functions
    modifier checkDeadline(uint256 deadline) {
        require(deadline > block.timestamp, ExpiredSignature());
        _;
    }

    constructor(address _subscriptionToken) {}

    // Create book functions
    function createEuphoriaBook(EuphoriaBook memory _book) external {}
    function createEuphoriaBookWithSig(EuphoriaBook memory _book, SigParams memory _sigParams) external {
        // requie deadline > block timestamp
    }
    function _createEuphoriaBook(EuphoriaBook memory _book, address _bookOwner) private {
        // make sure the owner is an author
        // make sure the owner is the actual owner of the book
    }

    // Create Chapter
    function releaseChapter(string memory _title) external {}
    function releaseChapterWithSig(string memory _title, SigParams memory _sigParams) external {
        // requie deadline > block timestamp
    }
    function _releaseChapter(string memory _title) private {
        // make sure the owner is an author
        // make sure the owner is the actual owner of the book
    }

    ///////

    function updateChapterLock(uint256 _bookId, uint256 _chapterLock) external {}
    function updateChapterLockWithSig(uint256 _bookId, uint256 _chapterLock, SigParams memory _sig) external {}
    function _updateChapterLock(uint256 _bookId, uint256 _chapterLock) private {}

    ///////

    function subscribe() external {}
    function subscribeWithSig(SigParams memory _sig) external {}
    function _subscribe() internal {}

    ////////

    function registerWriter(string memory _username) external {}
    function registerWriterWithSig(string memory _username, SigParams memory _sig) external {}
    function _registerWriter(string memory _username) external {}

    /////

    function useSpendBack(uint256 _bookId, uint256 _amount) external {}
    function useSpendBackWithSig(uint256 _bookId, uint256 _amount, SigParams memory _sig) external {}
    function _useSpendBack(uint256 _bookId, uint256 _amount) private {}

    function voteEuphoriaBook(uint256 _bookId, uint256 _votes) external {}
    function voteEuphoriaBookWithSig(uint256 _bookId, uint256 _votes, SigParams memory _sig) external {}
    function _voteEuphoriaBook(uint256 _bookId, uint256 _votes) external {}

    function startNewSeason() external {}

    function depositIntoBalance(uint256 _amount, address _recipient) external {}

    // testnet function only for ease of use
    function mintTokensIntoBalance() external {}

    function withdrawBalance(uint256 _amount, address _recipient) external {}
    function withdrawBalanceWithSig(uint256 _amount, address _recipient, SigParams memory _sig) external {}
    function _withdrawBalance(uint256 _amount, address _recipient) external {}

    // Season Details
    // struct Season {
    //     uint256 votes;
    //     uint256 votesExcercised;
    //     uint256 votingStartsAt;
    //     uint256 votingEndsAt;
    //     uint256 seasonAllocationAmount;
    // }
}
