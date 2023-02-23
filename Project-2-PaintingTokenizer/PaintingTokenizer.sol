// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PaintingNFT is ERC721, ERC721URIStorage {
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

    

    address owner;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("PaintingsNFT", "PNFT") {
        owner = msg.sender;
    }

    uint256 public constant mintPrice = 0;

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
    ) public minPrice(_price) returns (uint256) {
        Listing storage listing = listings[numberOfListings];

        actualCount++;
        numberOfListings++;

        listing.owner = msg.sender;
        listing.title = _title;
        listing.description = _description;
        listing.price = _price;
        listing.uri = _uri;
        listing.status = ListingStatus.active;
        listing.listingId = numberOfListings - 1;

        return numberOfListings - 1;
    }

    function removeListing(uint256 _listingId) public {
        Listing storage listing = listings[_listingId];

        require(
            listing.owner == msg.sender,
            "You are not the owner of the listing, only the owner can remove the listing"
        );

        listing.status = ListingStatus.removed;

        actualCount--;
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

        require(
            listing.price + mintPrice <= msg.value,
            "not enough funds sent"
        );

        uint256 tokenId = _tokenIdCounter.current();

        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        _setTokenURI(tokenId, listing.uri);

        payable(listing.owner).transfer(msg.value - mintPrice);

        listing.status = ListingStatus.sold;

        actualCount--;
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
            "minimum price should be greater than 0.0000005 eth"
        );
        _;
    }
}
