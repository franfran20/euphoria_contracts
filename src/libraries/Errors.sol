// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

library Errors {
    ///// Errors /////
    error NotRegisteredWriter();
    error InsufficientBalance();
    error BelowMinimumChapterLock();
    error InvalidGenreCount();
    error InvalidCharacterLength();
    error SignatureExpired();
    error InvalidSignature();
    error InvalidBookId();
    error NotBookOwner();
    error BookAlreadyCompleted();
    error SubscriptionStillActive();
    error InsufficientSpendBacks();
    error InvalidSelectedSeasonId();
    error SeasonOngoing();
    error AlreadyRegistered();
    error UsernameTaken();
    error InsufficientVotes();
}
