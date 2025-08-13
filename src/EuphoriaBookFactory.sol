// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IEuphoriaBookFactory} from "./interfaces/IEuphoriaBookFactory.sol";
import {Constants} from "./libraries/Constants.sol";
import {Errors} from "./libraries/Errors.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IFaucetToken} from "./interfaces/IFaucetToken.sol";

/**
 * @title Euphoria Book Contract Factory.
 * @notice handles all the logic for creating and interacting with books.
 * @dev some natspec that are straigtforward were ignore to avoid making the code clunky.
 */
contract EuphoriaBookFactory is IEuphoriaBookFactory {
    using SafeERC20 for IERC20;

    //// State Variables ////

    uint256 s_bookCreationCost;
    uint256 s_bookIds;

    uint256 i_subscriptionCost;
    uint256 i_subscriptionVotes;
    uint256 i_subscriptionDuration;

    uint256 s_currentSeasonId;
    uint256 i_votingDelay;
    uint256 i_votingDuration;

    IERC20 i_token;

    mapping(address user => User) s_users;
    mapping(address user => uint256 nonces) s_nonces;

    mapping(bytes32 usernameHash => bool taken) s_usernameTaken;
    mapping(address => string) s_username;

    mapping(address user => mapping(uint256 seasonId => uint256 votes)) s_userVotes;
    mapping(uint256 seasonId => Season) s_seasons;
    mapping(uint256 bookId => mapping(uint256 seasonId => uint256 votes)) s_bookVotes;

    mapping(uint256 bookId => EuphoriaBook) s_books;
    mapping(uint256 bookId => mapping(uint256 chapterId => string title)) s_chapterTitle;
    mapping(uint256 bookId => mapping(uint256 chapterId => string gatedURI)) s_chapterGatedURI;
    mapping(uint256 bookId => mapping(uint256 chapterId => uint256 createdAt)) s_chapterCreatedAt;

    mapping(uint256 bookId => string name) s_bookName;
    mapping(uint256 bookId => string coverImage) s_coverImage;

    //// Constructor ////
    constructor(ConstructorParams memory _params) {
        i_token = IERC20(_params.token);

        i_subscriptionCost = _params.subscriptionCost;
        s_bookCreationCost = _params.bookCreationCost;

        i_subscriptionVotes = _params.subscriptionVotes;
        i_votingDelay = _params.votingDelay;
        i_votingDuration = _params.votingDuration;

        i_subscriptionDuration = _params.subscriptionDuration;

        _startNewSeason();
    }

    //// Modifiers /////

    modifier checkSigDeadline(uint256 deadline) {
        require(deadline > block.timestamp, Errors.SignatureExpired());
        _;
    }

    modifier bookExists(uint256 bookId) {
        require(bookId <= s_bookIds, Errors.InvalidBookId());
        _;
    }

    modifier isBookWriter(uint256 bookId, address user) {
        require(s_books[bookId].owner == user, Errors.NotBookOwner());
        _;
    }

    //// External Functions ////

    /* create books */

    /// @inheritdoc IEuphoriaBookFactory
    function createEuphoriaBook(
        uint16 _chapterLock,
        string memory _name,
        string memory _coverImage,
        uint256[] memory _genres
    ) external returns (uint256) {
        User memory user = s_users[msg.sender];
        uint256 bookId = _createEuphoriaBook(_chapterLock, _name, _coverImage, _genres, msg.sender, user);
        return bookId;
    }

    /// @inheritdoc IEuphoriaBookFactory
    function createEuphoriaBookWithSig(
        uint16 _chapterLock,
        string memory _name,
        string memory _coverImage,
        uint256[] memory _genres,
        SigParams memory _sig
    ) external checkSigDeadline(_sig.deadline) returns (uint256) {
        User memory user = s_users[_sig.user];

        // sig verification
        bytes32 hashStruct = keccak256(
            abi.encode(
                Constants.CREATE_BOOK_TYPEHASH,
                _chapterLock,
                keccak256(bytes(_name)),
                keccak256(bytes(_coverImage)),
                keccak256(abi.encodePacked(_genres)),
                s_nonces[_sig.user],
                _sig.deadline
            )
        );
        _validateSig(hashStruct, _sig);
        uint256 bookId = _createEuphoriaBook(_chapterLock, _name, _coverImage, _genres, _sig.user, user);
        return bookId;
    }

    /* release chapters */

    /// @inheritdoc IEuphoriaBookFactory
    function releaseChapter(uint256 _bookId, string memory _title, string memory _gatedURI, bool _finale)
        external
        bookExists(_bookId)
        isBookWriter(_bookId, msg.sender)
        returns (uint256)
    {
        _releaseChapter(_bookId, _title, _gatedURI, _finale);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function releaseChapterWithSig(
        uint256 _bookId,
        string memory _title,
        string memory _gatedURI,
        bool _finale,
        SigParams memory _sig
    ) external bookExists(_bookId) isBookWriter(_bookId, _sig.user) checkSigDeadline(_sig.deadline) returns (uint256) {
        // sig verification
        bytes32 hashStruct = keccak256(
            abi.encode(
                Constants.RELEASE_CHAPTER_TYPEHASH,
                _bookId,
                keccak256(bytes(_title)),
                keccak256((bytes(_gatedURI))),
                _finale,
                s_nonces[_sig.user],
                _sig.deadline
            )
        );
        _validateSig(hashStruct, _sig);
        _releaseChapter(_bookId, _title, _gatedURI, _finale);
    }

    /* subscribe */

    /// @inheritdoc IEuphoriaBookFactory
    function subscribe() external {
        _subscribe(msg.sender);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function subscribeWithSig(SigParams memory _sig) external {
        // sig verification
        bytes32 hashStruct =
            keccak256(abi.encode(Constants.SUBSCRIBE_TYPEHASH, i_subscriptionCost, s_nonces[_sig.user], _sig.deadline));
        _validateSig(hashStruct, _sig);
        _subscribe(_sig.user);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function registerWriter(string memory _username) external {
        _registerWriter(_username, msg.sender);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function registerWriterWithSig(string memory _username, SigParams memory _sig) external {
        // sig verification
        bytes32 hashStruct = keccak256(
            abi.encode(Constants.REGISTER_TYPEHASH, keccak256(bytes(_username)), s_nonces[_sig.user], _sig.deadline)
        );
        _validateSig(hashStruct, _sig);
        _registerWriter(_username, _sig.user);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function useSpendBack(uint256 _bookId, uint256 _amount) external bookExists(_bookId) {
        _useSpendBack(_bookId, _amount, msg.sender);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function useSpendBackWithSig(uint256 _bookId, uint256 _amount, SigParams memory _sig)
        external
        bookExists(_bookId)
    {
        // sig verification
        bytes32 hashStruct = keccak256(
            abi.encode(Constants.USE_SPENDBACK_TYPEHASH, _bookId, _amount, s_nonces[_sig.user], _sig.deadline)
        );
        _validateSig(hashStruct, _sig);
        _useSpendBack(_bookId, _amount, _sig.user);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function voteEuphoriaBook(uint256 _bookId, uint256 _votes) external {
        _voteEuphoriaBook(_bookId, _votes, msg.sender);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function voteEuphoriaBookWithSig(uint256 _bookId, uint256 _votes, SigParams memory _sig) external {
        // sig verification
        bytes32 hashStruct =
            keccak256(abi.encode(Constants.VOTE_BOOK, _bookId, _votes, s_nonces[_sig.user], _sig.deadline));
        _validateSig(hashStruct, _sig);

        _voteEuphoriaBook(_bookId, _votes, _sig.user);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function startNewSeason() external {
        require(block.timestamp > s_seasons[s_currentSeasonId].votingEndsAt, Errors.SeasonOngoing());
        _startNewSeason();
    }

    /// @inheritdoc IEuphoriaBookFactory
    function pullSeasonsEarnings(uint256 _bookId, uint256 _toSeasonId) external {
        uint256 lastPulledSeasonId = s_books[_bookId].lastPulledSeasonId;
        require(_toSeasonId < s_currentSeasonId && _toSeasonId > lastPulledSeasonId, Errors.InvalidSelectedSeasonId());

        uint256 amountToPull;
        address bookOwner = s_books[_bookId].owner;

        for (uint256 season = lastPulledSeasonId + 1; season <= _toSeasonId; season++) {
            amountToPull += getBookSeasonAmount(_bookId, season);
        }

        s_users[bookOwner].depositedBalance += amountToPull;
        s_books[_bookId].lastPulledSeasonId = _toSeasonId;

        // tracking purposes
        s_users[bookOwner].withdrawnBookEarnings += amountToPull;
        s_books[_bookId].earnings += amountToPull;

        emit BookSeasonEarningsPulled(_bookId, amountToPull);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function depositIntoBalance(uint256 _amount, address _recipient) external {
        s_users[_recipient].depositedBalance += _amount;
        i_token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @inheritdoc IEuphoriaBookFactory
    function withdrawBalance(uint256 _amount, address _recipient) external {
        require(s_users[msg.sender].depositedBalance >= _amount, Errors.InsufficientBalance());

        s_users[msg.sender].depositedBalance -= _amount;
        i_token.safeTransfer(_recipient, _amount);
    }

    //// Private Functions ////

    /// @dev private function for creating euphoria book
    function _createEuphoriaBook(
        uint16 _chapterLock,
        string memory _name,
        string memory _coverImage,
        uint256[] memory _genres,
        address _user,
        User memory user
    ) private returns (uint256) {
        require(user.isWriter, Errors.NotRegisteredWriter());
        require(user.depositedBalance >= s_bookCreationCost, Errors.InsufficientBalance());
        require(_genres.length == uint8(Constants.SET_GENRE_COUNT), Errors.InvalidGenreCount());
        require(bytes(_name).length <= Constants.MAX_CHARACTER_LENGTH, Errors.InvalidCharacterLength());
        require(_chapterLock >= Constants.MIN_CHAPTER_LOCK, Errors.BelowMinimumChapterLock());

        s_bookIds += 1;
        uint256 bookId = s_bookIds;

        s_books[bookId] = EuphoriaBook({
            owner: _user,
            createdAt: block.timestamp,
            chapterLock: _chapterLock,
            chaptersWritten: 0,
            genres: _genres,
            completed: false,
            lastPulledSeasonId: 0,
            earnings: 0
        });

        s_users[_user].booksWritten += 1;
        s_bookName[bookId] = _name;
        s_coverImage[bookId] = _coverImage;

        emit EuphoriaBookCreated(bookId, _coverImage, _name, s_username[_user], _genres, block.timestamp, false, 0, 0);

        return bookId;
    }

    /// @dev private function for relaeasing book chapters
    function _releaseChapter(uint256 _bookId, string memory _title, string memory _gatedURI, bool _finale)
        private
        returns (uint256)
    {
        require(!s_books[_bookId].completed, Errors.BookAlreadyCompleted());

        s_books[_bookId].chaptersWritten += 1;

        uint256 createdChapter = s_books[_bookId].chaptersWritten;

        s_chapterTitle[_bookId][createdChapter] = _title;
        s_chapterGatedURI[_bookId][createdChapter] = _gatedURI;
        s_chapterCreatedAt[_bookId][createdChapter] = block.timestamp;
        if (_finale) s_books[_bookId].completed = true;

        address _bookOwner = s_books[_bookId].owner;

        emit ChapterReleased(
            _bookId,
            s_bookName[_bookId],
            s_username[_bookOwner],
            s_books[_bookId].chaptersWritten,
            _finale,
            _title,
            block.timestamp
        );

        return createdChapter;
    }

    /// @dev private function for handling subscriptions
    function _subscribe(address _user) private {
        User memory user = s_users[_user];
        uint256 currentSeasonId = s_currentSeasonId;
        uint256 subscriptionCost = i_subscriptionCost;

        require(block.timestamp > user.subscriptionEndsAt, Errors.SubscriptionStillActive());
        require(user.depositedBalance >= subscriptionCost, Errors.InsufficientBalance());

        uint256 spendBackAmount = (subscriptionCost * Constants.SPEND_BACK_SHARE) / Constants.WAD;
        uint256 seasonAmount = subscriptionCost - spendBackAmount;

        s_users[_user].depositedBalance -= subscriptionCost;
        s_users[_user].spendBacks += spendBackAmount;
        s_users[_user].subscriptionEndsAt = block.timestamp + i_subscriptionDuration;

        // if current season is over, assign funds to next season
        if (block.timestamp > s_seasons[currentSeasonId].votingEndsAt) currentSeasonId += 1;

        s_userVotes[_user][currentSeasonId] += i_subscriptionVotes;
        s_seasons[currentSeasonId].votes += i_subscriptionVotes;
        s_seasons[currentSeasonId].seasonAllocationAmount += seasonAmount;
    }

    /// @dev private function for handling writer registrations
    function _registerWriter(string memory _username, address _user) private {
        require(!s_users[_user].isWriter, Errors.AlreadyRegistered());
        require(bytes(_username).length <= Constants.MAX_CHARACTER_LENGTH, Errors.InvalidCharacterLength());
        require(!s_usernameTaken[keccak256(bytes(_username))], Errors.UsernameTaken());

        s_username[_user] = _username;
        s_users[_user].isWriter = true;
        s_usernameTaken[keccak256(bytes(_username))] = true;
    }

    /// @dev private function for using spend backs
    function _useSpendBack(uint256 _bookId, uint256 _amount, address _user) private {
        require(_amount <= s_users[_user].spendBacks, Errors.InsufficientSpendBacks());

        address bookOwner = s_books[_bookId].owner;

        s_users[_user].spendBacks -= _amount;
        s_users[bookOwner].depositedBalance += _amount;

        // tracker
        s_books[_bookId].earnings += _amount;

        emit SpendBackAllocated(_bookId, _amount);
    }

    /// @dev private function for voting for euphoria books
    function _voteEuphoriaBook(uint256 _bookId, uint256 _votes, address _user) private {
        uint256 currentSeasonId = s_currentSeasonId;
        require(s_userVotes[_user][currentSeasonId] >= _votes, Errors.InsufficientVotes());

        s_seasons[currentSeasonId].votesExcercised += _votes;
        s_bookVotes[_bookId][currentSeasonId] += _votes;
    }

    /// @dev private function for starting new season
    function _startNewSeason() private {
        uint256 previousSeasonAllocations = s_seasons[s_currentSeasonId].seasonAllocationAmount;
        uint256 previousSeasonId = s_currentSeasonId;

        s_currentSeasonId += 1;

        uint256 newSeasonId = s_currentSeasonId;
        s_seasons[newSeasonId].votingStartsAt = block.timestamp + i_votingDelay;
        s_seasons[newSeasonId].votingEndsAt = block.timestamp + i_votingDelay + i_votingDuration;

        emit SeasonFinished(previousSeasonId, previousSeasonAllocations);
    }

    //// Internal Functions ////

    function _validateSig(bytes32 _hashStruct, SigParams memory _sig) internal {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), _hashStruct));
        address recoveredAddress = ecrecover(digest, _sig.v, _sig.r, _sig.s);
        require(recoveredAddress != address(0) && recoveredAddress == _sig.user, Errors.InvalidSignature());
        s_nonces[_sig.user] += 1;
    }

    //// Getter Function ////

    /// @dev gets the amount earned by a book in a particular season
    // if the seaosn is the current season and it is still ongoing this value can be skewed
    function getBookSeasonAmount(uint256 _bookId, uint256 _seasonId) public view returns (uint256) {
        uint256 bookVotes = s_bookVotes[_bookId][_seasonId];
        uint256 votesExcercised = s_seasons[_seasonId].votesExcercised;
        uint256 seasonAllocations = s_seasons[_seasonId].seasonAllocationAmount;

        uint256 bookSeasonAmount;

        if (votesExcercised == 0) bookSeasonAmount = 0;
        else bookSeasonAmount = (bookVotes * seasonAllocations) / votesExcercised;

        return bookSeasonAmount;
    }

    /// @dev gets the book creation cost and subscription cost
    function getCosts() public view returns (uint256, uint256) {
        return (s_bookCreationCost, i_subscriptionCost);
    }

    /// @dev gets the current season details and total books
    function getCurrentSeason() public view returns (Season memory, uint256, uint256) {
        return (s_seasons[s_currentSeasonId], s_currentSeasonId, s_bookIds);
    }

    /// @dev gets the users details and nonce
    function getUser(address _user) public view returns (User memory, string memory, uint256) {
        return (s_users[_user], s_username[_user], s_nonces[_user]);
    }

    /// @dev gets the book details
    function getBook(uint256 _bookId)
        public
        view
        returns (EuphoriaBook memory, string memory, string memory, string memory, uint256)
    {
        return (
            s_books[_bookId],
            s_bookName[_bookId],
            s_username[s_books[_bookId].owner],
            s_coverImage[_bookId],
            s_bookVotes[_bookId][s_currentSeasonId]
        );
    }

    /// @dev checks if the username is taken
    function isUsernameTaken(string memory _username) public view returns (bool) {
        return s_usernameTaken[keccak256(bytes(_username))];
    }

    /// @dev gets the current user votes for the season
    function getUserVotes(address _user) public view returns (uint256) {
        return s_userVotes[_user][s_currentSeasonId];
    }

    /// @dev get the chapter details and ID
    function getChapter(uint256 _bookId, uint256 _chapterId) public view returns (uint256, string memory, uint256) {
        return (_chapterId, s_chapterTitle[_bookId][_chapterId], s_chapterCreatedAt[_bookId][_chapterId]);
    }

    /// @dev checks if the user has access to the book's content, used off-chain
    function hasAccess(uint256 _bookId, address _user, uint256 _chapterId) public view returns (bool) {
        uint256 bookChapterLock = s_books[_bookId].chapterLock;
        address bookOwner = s_books[_bookId].owner;
        bool isSubscribed = block.timestamp > s_users[_user].subscriptionEndsAt ? false : true;

        if (_user == bookOwner) return true;
        if (_chapterId < bookChapterLock) return true;
        if (isSubscribed) return true;

        return false;
    }

    /// @dev gets the current timestamp
    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    /// @dev constructs the domain separator
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                Constants.DOMAIN_TYPEHASH,
                keccak256(bytes("EuphoriaBookFactory")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// testnet function only for ease of use
    function mintTokensIntoBalance(uint256 _amount, address _recipient) external {
        IFaucetToken(address(i_token)).mint(address(this), _amount);
        s_users[_recipient].depositedBalance += _amount;
    }
}
