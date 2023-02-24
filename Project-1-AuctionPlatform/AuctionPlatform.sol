//SPDX-License-Identifier: MIT;
pragma solidity ^0.4.24;

// importing BokkyPooBahsDateTime Library for converting Date to timestamp;
import "https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/1ea8ef42b3d8db17b910b46e4f8c124b59d77c03/contracts/BokkyPooBahsDateTimeLibrary.sol";

// importing Auction contract to use for making Auctions;
import "./Auction.sol";

contract AuctionPlatform {
    uint256 public aucId = 0; // this variable keeps track of number of auctions and also acts as aucionId;
    Auction[] auctionList; // list of all the auctions created;
    mapping(address => uint256) aucOwners; // address of Auction owners to aucId;
    mapping(address => uint256[]) bidOwners; // address of Bidders mapped to aucIds;

    // Event for logging that auction is created with the aucId by the address at the given time.
    event auctionCreated(
        uint256 indexed _aucId,
        uint256 indexed _timeStamp,
        address from
    );

    // Event for logging that auction is ended with the given winner and its winning Bid.
    event auctionEnded(address indexed _winner, uint256 indexed _winningBid);

    // Event for logging that the given address has bidded on the auction with the given aucId.
    event biddedOnAuction(address indexed from, uint256 indexed _aucId);

    // Event for logging that bid has been updated
    event updatedBid(address indexed from, uint256 indexed _aucId);

    constructor(uint _auctionLimit) public {
        auctionList.length = _auctionLimit + 1;
    }

    //  this function gives the list of bids with their amounts to the owner of the auction
    function getListOfBidsOnAuction()
        public
        view
        ifAuctionOwner
        isBidsMade
        returns (uint256[])
    {
        return auctionList[aucOwners[msg.sender]].getListOfBids();
    }

    // this function gives the list of bids bidded by the address owner on different auctions
    function getListOfOwnBids() public view ifBidded returns (uint256[]) {
        return bidOwners[msg.sender];
    }

    // function to get minimum bid value of the auction corresponding to aucId
    function getMinBidValOfAuction(uint _aucId) public isRunning(_aucId) view returns(uint256){
        return auctionList[_aucId].getMinBidVal();
    }

    // returns the bidded amount on the auction specified by the aucId
    function getBidValOnAuction(uint256 _aucId)
        public
        view
        ifBidded
        isRunning(_aucId)
        returns (uint256)
    {
        return auctionList[_aucId].bids(msg.sender);
    }

    // this gives the maximum bid on the auction of the address owner
    function getMaxBid()
        public
        view
        ifAuctionOwner
        isBidsMade
        returns (uint256)
    {
        // mapping of aucOwners returns the aucId corresponding to the address passed which in turn is used to access the
        // Auctino object through the auctionList. then the getMaximumBid function is called
        return auctionList[aucOwners[msg.sender]].getMaximumBid();
    }

    function getMaxBid(uint256 _aucId)
        public
        view
        isBidsMade
        returns (uint256)
    {
        return auctionList[_aucId].getMaximumBid();
    }

    // this function ends the auction by automatically selecting the maximum bid on the autction and returns the address of the winner
    function endAuction() public ifAuctionOwner returns (address) {
        // same as line 46
        uint256 maxBid = auctionList[aucOwners[msg.sender]].getMaximumBid();

        // mapping of aucOwners returns the aucId corresponding to the address passed which in turn is used to access the
        // Auction object through the auctionList. then the endAuctionWithSelectedBid is called and the maxBid is passed to it as Argument
        address winner = auctionList[aucOwners[msg.sender]]
            .endAuctionWithSelectedBid(maxBid);

        emit auctionEnded(winner, maxBid);

        return winner;
    }

    // this function ends the auction by selecting the winner with the bid passed as argument to it. It emits the address of the winner with the bid
    function endAuction(uint256 _bid) public ifAuctionOwner {
        // same as 60 except the argument is bid except of maxBid
        address winner = auctionList[aucOwners[msg.sender]]
            .endAuctionWithSelectedBid(_bid);
        emit auctionEnded(winner, _bid);
    }

    // Function to Bid on auction takes aucId and Bid Value as arguments
    function bidOnAuction(uint256 _aucId, uint256 _bidVal)
        public
        isRunning(_aucId) // modifier to check whether auction is active or not
    {
        // checks bid value if is greater than minimum bid value specified by the auction owner
        require(
            auctionList[_aucId].getMinBidVal() < _bidVal,
            "Bid value cannot be less than mininum bid value of auction"
        );

        require(aucOwners[msg.sender] != _aucId, "Can't bid on own Auction");

        // This line of code calls the createBid function of the Auction object by accessing it through given auction Id from auctionList array
        auctionList[_aucId].createBid(_bidVal);

        // appends the auction Id to the bids list of the person who called the function
        bidOwners[msg.sender].push(_aucId);

        emit biddedOnAuction(msg.sender, _aucId);
    }

    function updateBid(uint256 _aucId, uint256 _bidVal)
        public
        isRunning(_aucId)
    {
        auctionList[_aucId].updateBid(_bidVal); // calls the update Bid function which further checks other conditions;
        emit updatedBid(msg.sender, _aucId);
    }

    function createAuction(
        string memory _description, /// description of the item being auctioned
        uint256 _startTimeYear,
        uint256 _startTimeMonth,
        uint256 _startTimeDay, /// start time of auction in yyyy:mm:dd format
        uint256 _endTimeYear,
        uint256 _endTimeMonth,
        uint256 _endTimeDay, /// end time of auction in yyyy:mm:dd format
        uint256 _minBidVal /// Minimum Bid value of the contract
    )
        public
        isAlreadyAuctionOwner /// to check if the caller already owns an auction or not
    {
        require(aucId < auctionList.length-1,"Auctions Limit reached can't create anymore Auctions");
        // Checking if the dates entered are valid to be passed to the DateTime Library for converstion
        require(
            BokkyPooBahsDateTimeLibrary.isValidDateTime(
                _startTimeYear,
                _startTimeMonth,
                _startTimeDay,
                0,
                0,
                0
            ),
            "Enter Valid Start Date"
        );
        require(
            BokkyPooBahsDateTimeLibrary.isValidDateTime(
                _endTimeYear,
                _endTimeMonth,
                _endTimeDay,
                0,
                0,
                0
            ),
            "Enter Valid End Date"
        );

        // Converting the dates to timestamps using BokkyPooBahsDateTime Library imported from github on line 6
        uint256 start_time = BokkyPooBahsDateTimeLibrary.timestampFromDate(
            _startTimeYear,
            _startTimeMonth,
            _startTimeDay
        );

        uint256 end_time = BokkyPooBahsDateTimeLibrary.timestampFromDate(
            _endTimeYear,
            _endTimeMonth,
            _endTimeDay
        );

        // Checking wether the time given is valid and start time is less than end time;

        require(
            block.timestamp < start_time &&
                block.timestamp < end_time &&
                start_time < end_time,
            " Please enter a valid interval for the Auction"
        );

        aucId = aucId + 1; // incrementing aucId to keep track of auctions and their respective Ids
        Auction TempA = new Auction(
            _description,
            start_time,
            end_time,
            _minBidVal
        ); // creating new Auction object to store in array
        auctionList[aucId] = TempA; // appending the Auction object at the end of auction array
        aucOwners[msg.sender] = aucId; // mapping the address of the caller to aucId so that owner can manage the auction later

        emit auctionCreated(aucId, block.timestamp, msg.sender);
    }

    ///////// MODIFIERS /////////////

    // to check if bids are made on the aucition or not
    modifier isBidsMade() {
        require(
            auctionList[aucOwners[msg.sender]].getBidsMade(),
            "There aren't any bids on the Auction"
        );
        _;
    }

    // to check if auction is active or not
    modifier isRunning(uint256 _aucId) {
        require(
            _aucId <= aucId &&
                auctionList[_aucId].getEndTime() > block.timestamp,
            "Auction is Inactive"
        );
        _;
    }

    // to check if address owner has already created auction or not
    modifier isAlreadyAuctionOwner() {
        require(
            aucOwners[msg.sender] == 0,
            "You have already created an Auction"
        );
        _;
    }

    // to check if address owner has created any auctions or not
    modifier ifAuctionOwner() {
        require(aucOwners[msg.sender] != 0, "You haven't created any Auctions");
        _;
    }

    // to check if address has created any bids or not
    modifier ifBidded() {
        require(bidOwners[msg.sender].length != 0, "You don't have any Bids");
        _;
    }

    modifier bidValNotZero(uint256 bid) {
        require(bid > 0, "Minimum BidVal cannot be 0");
        _;
    }
}
