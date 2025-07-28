// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Constants {
    ///// Type Hashes /////

    // domain typehash
    bytes32 constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    // create euphoria book typehash
    bytes32 constant EUPHORIA_BOOK_TYPEHASH = keccak256(
        "EuphoriaBook(address owner,address bookAddress,uint64 releaseDate,uint16 chapterLock,uint16 chaptersWritten,string name,string author,string description,string coverImage,uint8[] genre)"
    );
}
