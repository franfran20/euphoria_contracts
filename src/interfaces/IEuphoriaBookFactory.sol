// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IEuphoriaBookFactory {
    ///// Errors /////
    error ExpiredSignature();

    /////// Types & Input Params /////////

    // Paramters for the "with sig" functions
    struct SigParams {
        uint256 deadline;
        uint256 nonce;
        bytes32 r;
        bytes32 s;
        address user;
        uint8 v;
    }

    // User Details
    struct User {
        string username;
        string bio;
        uint256 internalBalances;
        uint256 allocationBalances;
        uint256 withdrawnBookEarnings;
        uint256 booksWritten;
        uint256 subscriptionEndsAt;
        bool isWriter;
    }

    // Season Details
    struct Season {
        uint256 votes;
        uint256 votesExcercised;
        uint256 votingStartsAt;
        uint256 votingEndsAt;
        uint256 seasonAllocationAmount;
    }

    /// @notice Euphoria Book Struct
    struct EuphoriaBook {
        address owner;
        address bookAddress;
        uint64 createdAt;
        uint16 chapterLock;
        uint16 chaptersWritten;
        string name;
        string author;
        string coverImage; // cover image URI
        uint8[] genre;
    }

    /// @notice Euphoria Book Chapter Struct
    struct EuphoriaBookChapter {
        string title;
        uint256 createdAt;
    }

    /////// Events /////////

    /////// Functions /////////

    /**
     * @notice creates a euphoria book with the necessary book information
     * @dev some book information would be stored off-chain.
     *  Enforces that
     *  - the user creating the book either msg.sender or via sig is a registered writer
     *  - the registered writer is subscribed
     *  - the book creation cost is paid via the deposit balance
     *  - no more than 3 genres are selected
     *  - the author and name values all respect a fixed maxmum length
     */
    function createEuphoriaBook(EuphoriaBook memory _book) external;
    function createEuphoriaBookWithSig(EuphoriaBook memory _book, SigParams memory _sigParams) external;

    /**
     * @notice releases a chapter for a particular book by minting a new token Id with the chapter information
     * @dev some chapter details and content are stored off chain. The chapter content is gated via the isSubscribed() and
     *  the chapter lock information set by the writer for the book and the caller is not the book owner
     *  Enforces that
     *  - the book exists
     *  - the chapter title resepcts a fixed max length
     */
    function releaseChapter(string memory _title) external;
    function releaseChapterWithSig(string memory _title, SigParams memory _sigParams) external;

    /**
     * @notice updates the chapter lock. Essentially at what chapter does a user has to be subcribed to view gated content.
     *  @dev Enforces that
     *  - book exists
     *  - the caller is the book owner
     *  - must be >= chapter 3 to allow reading books early.
     */
    function updateChapterLock(uint256 _bookId, uint256 _chapterLock) external;
    function updateChapterLockWithSig(uint256 _bookId, uint256 _chapterLock, SigParams memory _sig) external;

    /**
     * @notice subscribes a user to be able to view content for a book chapter based on the isSubscribed(), the chapter lock and the book owner.
     *  As the chapter content would be off-chain, the validation process would be off chain as well.
     *  @dev the user receives spendBack's on subscription and votes for the ongoing/upcoming season.
     *  Enforced that
     *  - the subscription amount can be taken from the deposited balances
     *  - the user cannot double subscribe
     */
    function subscribe() external;
    function subscribeWithSig(SigParams memory _sig) external;

    /**
     * @notice register's a user as a writer with a username
     * @dev Enforces that
     *  - the username must not be longer than a fixed max length
     *  - the user must not already be registered as a writer
     */
    function registerWriter(string memory _username) external;
    function registerWriterWithSig(string memory _username, SigParams memory _sig) external;

    /**
     * @notice uses the spendback earned from subscription given to the user to allocate to an existing book
     *  @dev `spendBack` allocations are basically a portion of a users
     */
    function useSpendBack(uint256 _bookId, uint256 _amount) external;
    function useSpendBackWithSig(uint256 _bookId, uint256 _amount, SigParams memory _sig) external;

    function voteEuphoriaBook(uint256 _bookId, uint256 _votes) external;
    function voteEuphoriaBookWithSig(uint256 _bookId, uint256 _votes, SigParams memory _sig) external;

    function startNewSeason() external;

    function depositIntoBalance(uint256 _amount, address _recipient) external;

    // testnet function only for ease of use
    function mintTokensIntoBalance() external;

    function withdrawBalance(uint256 _amount, address _recipient) external;
    function withdrawBalanceWithSig(uint256 _amount, address _recipient, SigParams memory _sig) external;
}
