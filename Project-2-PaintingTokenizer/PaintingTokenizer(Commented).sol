// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



// importing openzepplin's implementation of ERC721 for minting NFT;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";    
// importing openzepplin's implementation of Counters function for keeping track of the nfts;                          
import "@openzeppelin/contracts/utils/Counters.sol";
// importing openzepplin's ERC721 extenstion ERC721URIStorage for storing the URI of the nft;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// importing SafeMath library for uint calculations;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



// contract inherits from ERC721 and ERC721URIStorage contracts to use and implement their functions;
contract PaintingNFT is ERC721,ERC721URIStorage{


    using Counters for Counters.Counter;
    using SafeMath for uint;

        ////////////////////////////// Overrides required //////////////////////////////////

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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

         ////////////////////////////// Overrides required //////////////////////////////////
    /// EVENTS ///

    // for logging the listing created with the listingid at the time by the address 
    event listingCreated(address indexed Lister,uint indexed listing_id,uint time);       

    // for logging the transaction that has taken place while buying the listing 
    event listingBought(address indexed Buyer,address indexed Seller,uint time); 

    // for logging that the listing has been removed by the owner
    event listingRemoved(address indexed from,uint indexed listingid);

    


    address owner; 

    uint public mintPrice;                           // initializing the mint price of the nft
                                                      // address of Owner to keep track of the owner of the contract
                                 // 
    Counters.Counter private _tokenIdCounter;                        // initializing _tokenCounter with Counters to keep track of the nfts

    // constructor which initializes the name and the symbol of the collection of NFTS as per ERC721 standards using the modfiers;
    constructor(string memory _name, string memory _symbol,uint _mintPrice) ERC721(_name,_symbol){                     
        owner = msg.sender;                                             // assigning address of the deployer of the contract to owner
        mintPrice = _mintPrice;                                         // definig mint price which is passed as argument to the constructor while deploying the contract
    }

                        

    // defining an enumeration for storing the status of the Listing
    enum ListingStatus{
        active,                                         // for when the listing is active
        sold,                                           // for when the listing has been sold
        removed                                         // for when the listing has been removed
    }
    // Listing struct to contain attributes of each listing seperately
    struct Listing {
        uint listingId;                                 // listing Id to keep track of the listing                          
        uint price;                                     // listing price in wei
        address owner;                                  // to store the address of the owner of the listing for later use                                  
        string title;                                   // string to store the title of the listing
        string description;                             // string to store the description of the listing
        string uri;                                     // string to store the uri of the image being minted if bought
        ListingStatus status;                           // enum to keep track of the status of the listing
    }

    // mapping of listingId to Listing;
    mapping(uint => Listing) listings;
    
    // this keeps track of the actual count of the listings which are active.
    uint public actualCount;
    // this keeps track of the total no. of listing created. doesn't matter if they were sold or removed.
    uint numberOfListings;   

 

    // function to create listing which takes as arguments the titel,description, uri and the price 
    function createListing(string memory _title, string memory _description, string memory _uri, uint _price) public minPrice(_price) {

        // initializing a Listing object and creating a pointer called "listing" that points to it
        Listing storage listing = listings[numberOfListings];         
        // increasing the actual count and numberOfListings respectively
        actualCount++;
        numberOfListings++;

        // updating all the attributes of the listing 
        listing.owner = msg.sender;                                           
        listing.title = _title;
        listing.description = _description;
        listing.price = _price + mintPrice;              //
        listing.uri = _uri;
        listing.status = ListingStatus.active;
        listing.listingId = numberOfListings-1; 
        


        
        uint listingid = numberOfListings - 1; 

        emit listingCreated(msg.sender,listingid,block.timestamp);
    
    }

    // function to remove the listing of the painting if the owner decides to
    function removeListing(uint _listingId) public{
        // creating a pointer "listing" to point to the respective listing as made clear using _listingId
        Listing storage listing = listings[_listingId];

        // require statement to check if the owner of the listing called the function or not
        require(listing.owner == msg.sender,"You are not the owner of the listing, only the owner can remove the listing");

        // updating the status of the listing to removed  
        listing.status = ListingStatus.removed;

        // decreasing the actualCount only as the total listings have decreased
        actualCount--;

        emit listingRemoved(msg.sender, _listingId);

    }

    // function to view all the listings which returns an array of Listings objects
    function viewListings() public view returns(Listing[] memory){
        
        // creating an array of Listing of size which is equal to actualCount
        Listing[] memory tempList = new Listing[](actualCount);


        // initializing j to keep track of acutalCount
        uint j = 0; 

        // storing numberOfListings in simliar variable so that we won't have to access it again and again in for loop which will save some gas
        uint _numberOfListings = numberOfListings;

        for(uint i;i<_numberOfListings;i++){
            // every iteration checks the status of the listing to see whether it is active or not
            if(listings[i].status==ListingStatus.sold || listings[i].status == ListingStatus.removed){
                continue;
            }else{
                // adding the listing to the array
                tempList[j] = listings[i];
                // incrementing the value of j
                j++;
            }

        }
        // finally returning the list of the Listings
        return tempList;

    }


    // function to buy the listing which mints the nft and transfers the amount sent to the owner of the listing

    function buyListing(uint _listingId) public payable validListingId(_listingId){


        
        // creating a pointer "listing" to point to the respective listing as made clear using _listingId
        Listing storage listing = listings[_listingId];

        // checking the status of the listing
        require(listing.status!=ListingStatus.sold && listing.status != ListingStatus.removed,"Listing is not active");

        // checking if the amount sent is equal to the addition of the minting price and the listing price
        require(listing.price<= msg.value,"not enough funds sent");


        // defining a token id for the mint function
         uint256 tokenId = _tokenIdCounter.current();

        // incrementing the counter 
        _tokenIdCounter.increment();

        // this function is from ERC721 which mints the nft with the tokenId passed as  the 2nd argument
        // for the address passed as the 1st argument
        _safeMint(msg.sender, tokenId);

        // sets the tokenURI which is the metadata of the nft 
        _setTokenURI(tokenId,listing.uri);

        address Owner = listing.owner;
        // transfering the amount sent to the owner of the listing
        payable(Owner).transfer(msg.value - mintPrice);

        // updating listing status to sold
        listing.status = ListingStatus.sold;

        // decrementing the actualCount as the listing has been sold
        actualCount--;

        emit listingBought(msg.sender,Owner,block.timestamp);

    }


    //////////// MODIFIERS ////////////////

    // to check if the owner of the contract is calling the function or not
    modifier onlyOwner(){
        require(msg.sender==owner,"only Owner can withdraw funds");
        _;
    }
    
    // to check if the listingId given is a valid one or not
    modifier validListingId(uint _listingId) {
        require(_listingId<numberOfListings,"Enter a valid Id of the Listing you want");
        _;
    }

    // to check if the price of the listing is greater than the mint price 
    modifier minPrice(uint _price){
        require(_price>mintPrice,"minimum price should be greater than 0.0000005 eth");
        _;
    }


    // Functions which can be implemented later 

       // function withdrawAmount() public payable onlyOwner{
    //     payable(msg.sender).transfer(address(this).balance);
    // }

    // function viewFunds() public view onlyOwner returns(uint){
    //     return address(this).balance;
    // }

}