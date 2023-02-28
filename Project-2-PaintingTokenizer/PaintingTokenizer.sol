// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PaintingTokenizer is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

     
    event listingCreated(address indexed Lister,uint indexed listing_id,uint time);       

    
    event listingBought(address indexed Buyer,address indexed Seller,uint time); 

   
    event listingRemoved(address indexed from,uint indexed listingid);


    address owner;
    uint256 public mintPrice;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory _name, string memory _symbol, uint _mintPrice) ERC721(_name, _symbol) {
        owner = msg.sender;
        mintPrice = _mintPrice;
    }

    

    enum ListingStatus {
        active,
        sold,
        removed
    }

    struct Listing {
        uint256 listingId;
        uint256 price;
        address owner;
        string title;
        string description;
        string uri;
        ListingStatus status;
    }

    mapping(uint256 => Listing) listings;

    uint256 public actualCount;

    uint256 numberOfListings;

    function createListing(
        string memory _title,
        string memory _description,
        string memory _uri,
        uint256 _price
    ) public minPrice(_price) {
        Listing storage listing = listings[numberOfListings];

        actualCount++;
        numberOfListings++;

        listing.owner = msg.sender;
        listing.title = _title;
        listing.description = _description;
        listing.price = _price + mintPrice;       //
        listing.uri = _uri;
        listing.status = ListingStatus.active;
        listing.listingId = numberOfListings - 1;

        uint listingid = numberOfListings - 1; 

        emit listingCreated(msg.sender,listingid,block.timestamp);
    }

    function removeListing(uint256 _listingId) public {
        Listing storage listing = listings[_listingId];

        require(
            listing.owner == msg.sender,
            "You are not the owner of the listing, only the owner can remove the listing"
        );

        listing.status = ListingStatus.removed;

        actualCount--;

        emit listingRemoved(msg.sender, _listingId);
    }

    function viewListings() public view returns (Listing[] memory) {
        Listing[] memory tempList = new Listing[](actualCount);

        uint256 j = 0;

        uint256 _numberOfListings = numberOfListings;

        for (uint256 i; i < _numberOfListings; i++) {
            if (
                listings[i].status == ListingStatus.sold ||
                listings[i].status == ListingStatus.removed
            ) {
                continue;
            } else {
                tempList[j] = listings[i];

                j++;
            }
        }

        return tempList;
    }

    function buyListing(uint256 _listingId)
        public
        payable
        validListingId(_listingId)
    {
        
        Listing storage listing = listings[_listingId];

        require(
            listing.status != ListingStatus.sold &&
                listing.status != ListingStatus.removed,
            "Listing is not active"
        );

        require(listing.owner != msg.sender,"Cannot Buy own Listing");

        require(
            listing.price <= msg.value,
            "not enough funds sent"
        );

        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        _setTokenURI(tokenId, listing.uri);

        address Owner = listing.owner;

        payable(Owner).transfer(msg.value - mintPrice);

        listing.status = ListingStatus.sold;

        actualCount--;

        emit listingBought(msg.sender,Owner,block.timestamp);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner can withdraw funds");
        _;
    }

    modifier validListingId(uint256 _listingId) {
        require(
            _listingId < numberOfListings,
            "Enter a valid Id of the Listing you want"
        );
        _;
    }

    modifier minPrice(uint256 _price) {
        require(
            _price > mintPrice,
            "minimum price should be greater than mint Price"
        );
        _;
    }
}
