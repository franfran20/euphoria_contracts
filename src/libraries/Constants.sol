// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Constants {
    ///// Constants /////

    uint8 constant SET_GENRE_COUNT = 3;
    uint8 constant MAX_CHARACTER_LENGTH = 30;
    uint8 constant MIN_CHAPTER_LOCK = 2;
    uint256 constant SPEND_BACK_SHARE = 0.5e18; // 50%
    uint256 constant WAD = 1e18; // 100%

    // Type Hash

    // domain typehash
    bytes32 constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // create euphoria book typehash
    bytes32 constant CREATE_BOOK_TYPEHASH = keccak256(
        "EuphoriaBook(uint16 chapterLock,string name,string coverImage,uint256[] genre,uint256 nonce,uint256 deadline)"
    );
    // release chapter typehash
    bytes32 constant RELEASE_CHAPTER_TYPEHASH = keccak256(
        "ReleaseChapter(uint256 bookId,string title,string gatedURI,bool finale,uint256 nonce,uint256 deadline)"
    );
    // subscribe typehash
    bytes32 constant SUBSCRIBE_TYPEHASH =
        keccak256("Subscribe(uint256 subscriptionCost,uint256 nonce,uint256 deadline)");
    // register typehash
    bytes32 constant REGISTER_TYPEHASH = keccak256("Register(string username,uint256 nonce,uint256 deadline)");
    // use spendback typehash
    bytes32 constant USE_SPENDBACK_TYPEHASH =
        keccak256("UseSpendBack(uint256 bookId,uint256 amount,uint256 nonce,uint256 deadline)");
    bytes32 constant VOTE_BOOK = keccak256("VoteBook(uint256 bookId,uint256 votes,uint256 nonce,uint256 deadline)");
}
