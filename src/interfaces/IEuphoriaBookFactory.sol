// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IEuphoriaBookFactory {
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

    // Constructor Parameters
    struct ConstructorParams {
        address token;
        uint256 bookCreationCost;
        uint256 subscriptionCost;
        uint256 subscriptionVotes;
        uint256 subscriptionDuration;
        uint256 votingDelay;
        uint256 votingDuration;
    }

    // User Details
    struct User {
        uint256 depositedBalance;
        uint256 spendBacks;
        uint256 withdrawnBookEarnings; // lifetime: for tracking purposes only
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
        uint256 createdAt;
        uint16 chapterLock;
        uint16 chaptersWritten;
        uint256[] genres;
        bool completed;
        uint256 lastPulledSeasonId;
        uint256 earnings; // lifetime: for tracking purposes only
    }

    /////// Events /////////

    // emit on book creation
    event EuphoriaBookCreated(
        uint256 bookId,
        string coverImage,
        string name,
        string writer,
        uint256[] genres,
        uint256 createdAt,
        bool completed,
        uint256 chaptersWritten,
        uint256 earnings
    );

    // emit on succesfull chapter release
    event ChapterReleased(
        uint256 bookId, string bookName, string writer, uint256 chapterId, bool finale, string title, uint256 writtenAt
    );

    // emit on sucessful spendback allocation
    event SpendBackAllocated(uint256 bookId, uint256 amount);

    // emit on succesfull book season rewards pull
    event BookSeasonEarningsPulled(uint256 bookId, uint256 amountToPull);

    // emit on succesful season finished
    event SeasonFinished(uint256 seasonId, uint256 seasonAllocations);

    /////// Functions /////////

    /**
     * @notice creates a euphoria book with the necessary book information
     * @dev some book information would be stored off-chain.
     *  Enforces that
     *  - the user creating the book either msg.sender or via sig is a registered writer
     *  - the book creation cost is paid via the deposit balance
     *  - no more than 3 genres are selected
     *  - the author and name values all respect a fixed maxmum length
     * //
     */
    function createEuphoriaBook(
        uint16 _chapterLock,
        string memory _name,
        string memory _coverImage,
        uint256[] memory _genres
    ) external;
    function createEuphoriaBookWithSig(
        uint16 _chapterLock,
        string memory _name,
        string memory _coverImage,
        uint256[] memory _genres,
        SigParams memory _sigParams
    ) external;

    /**
     * @notice releases a chapter for a particular book
     * @dev some chapter details and content are stored off chain. The chapter content is gated via the hasAccess() and
     *  the chapter lock information set by the writer for the book when the caller is not the book owner and not subscribed
     *  The _finale is basically used to know if the book is completd or not.
     *  Enforces that
     *  - the book exists
     *  - the chapter title resepcts a fixed max length
     */
    function releaseChapter(uint256 _bookId, string memory _title, bool _finale) external;
    function releaseChapterWithSig(uint256 _bookId, string memory _title, bool _finale, SigParams memory _sigParams)
        external;

    /**
     * @notice subscribes a user to be able to view content for a book chapter based on the hasAccess(), the chapter lock and the book owner.
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
     *  @dev `spendBack` allocations are basically a portion of a users subscription balance that are not allocated to
     *  a season's pool but instead returned to the user to be able to support books they enjoyed.
     *  Enforces that
     *  - the book exists
     *  - the amount > 0
     *  - the spendback balance is >= amount
     */
    function useSpendBack(uint256 _bookId, uint256 _amount) external;
    function useSpendBackWithSig(uint256 _bookId, uint256 _amount, SigParams memory _sig) external;

    /**
     * @notice allocates votes to a euphoria book for a particular season
     * @dev each user is allocated votes when they subscribe either to the upcoming season or ongoing season if active
     *  These votes are valid for the user for the user regardless of if their subscription ended when the season began.
     *  Enforces that
     *  - the book must exist
     *  - the user allocated votes >= _votes
     *  - the season voting period should have not ended
     */
    function voteEuphoriaBook(uint256 _bookId, uint256 _votes) external;
    function voteEuphoriaBookWithSig(uint256 _bookId, uint256 _votes, SigParams memory _sig) external;

    /**
     * @notice starts a new season i.e opens a new voting startsAt and votingEndsAt
     * @dev  Enforces that
     *  - the current time > voting ends at for the previous season
     */
    function startNewSeason() external;

    /**
     * @notice pulls the book earnings accross different seasons, as the earnings are not automatically
     *  allocated to the books at the end of the season.
     *  @dev loops through the past seasons from the last pulled season for the book and gets the books share based on the votes, there is a getter function for this.
     *   Anyone can call this function on behalf of the book owner and it goes straight to deposited balances of the writer
     *  Enforces that
     *  - the book must exist
     *  - the _toSeasonId must be be greater than the `lastPulledSeason` for the book
     *  - the _toSeasonId must not also be equal to the current seasonId i.e you can only pull from past seasons
     */
    function pullSeasonsEarnings(uint256 _bookId, uint256 _toSeasonId) external;

    /**
     * @notice deposits the supported token into the users internal balances.
     *  Created to reduce the need for approvals or permits and then signatures for the actions that would've required
     *  a transferFrom
     * @dev most things that require a fee, charge or earning go into the users deposit balance
     *  The amount is the amount of the supported token, while the recipient is the user who receives the amount in their deposited balances
     *  Enforces thta
     *   - the amount > 0 and the recipient != address(0)
     */
    function depositIntoBalance(uint256 _amount, address _recipient) external;

    /**
     * @notice withdraws the amount from the caller or signers internal balances to the specified recipient
     *  @dev Enforces that
     *  - the caller/signer balance >= amount
     *  - the amount > 0 and the recipient != address(0)
     */
    function withdrawBalance(uint256 _amount, address _recipient) external;

    // testnet function only for ease of use
    /// @dev mints the supported testnet tokens straight form the test token to the internal balances for the recipient
    // by minting the tokens from the faucet to this contract and incrementing the internal balances.
    function mintTokensIntoBalance(uint256 _amount, address _recipient) external;
}
