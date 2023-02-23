// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;




contract Auction {
    


    string description;                         // description of the item being auctioned
    uint startTime;                             // time in timestamp to specify start of the auction
    uint endTime;                               // time in timestamp to specify end of the auction
    uint minBidVal;                             // minimum bid value of the auction in eth
    
    bool bidsMade;                              // flag to check if bids are made on the auction or not

    mapping(address => uint) bids;              // mapping of the address to bids to keep track of bidders and thier bid values
    address[] biddersList;                      // list of bidders to access the mappings of bids easily


    // getter for bidsMade used in AuctionPlatform
    function getBidsMade() external view returns(bool){
        return bidsMade;
    }

    // getter for endTime used in AuctionPlatform
    function getEndTime() external view returns(uint256){
        return endTime;
    }

    // getter for minBidVal
    function getMinBidVal() external isActive view returns(uint){
        return minBidVal;
    }


    // max function used for finding out maximum bids from the list of bids on line 97
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    // function to get the list of bids on the contract
    function getListOfBids() external isActive view returns(uint[]){
        
        // creating a temporary array to add the bid values 
        uint[] memory list = new uint[](biddersList.length);   

        // adding elements to the array by accessing the bids mapping by using the array of owners of the bids   
        for(uint i;i<biddersList.length;i++){
            
            list[i] = bids[biddersList[i]];                     

        }

        return list;
    }

    // to create an auction of the desired parameters. Gets called when we create an auction in AuctionPlatform
    
    constructor(string memory _description, uint _startTime, uint _endTime, uint _minBidVal) public {
        
        // same as line 10-13
        description = _description;
        startTime = _startTime;
        endTime = _endTime;
        minBidVal = _minBidVal;
    
    }

    // function to create a bid with the given bid value 
    function createBid(uint _bidVal) external validBidVal(_bidVal) isActive isBidPresent {

        bidsMade = true;                   // marks the bidsMade flag as true
        bids[tx.origin] = _bidVal;          // mapping the address of the owner to the bid value to keep track of the bids
        biddersList.push(tx.origin);        // adding the address of the owner to biddersList array to easily access the bids mapping

        
    }

    // function to update the bid with the given value
    function updateBid(uint _bidVal) external validBidVal(_bidVal) isActive {
        require(bids[tx.origin]!=0,"You haven't created any bid, use createBid for creating one"); // check if the bidder has created a bid or not
        bids[tx.origin] = _bidVal;
    }


    // function to end the auction with the selected bid passed as argument below
    function endAuctionWithSelectedBid(uint bid) external isActive isBidsMade returns(address){
        endTime = block.timestamp;                     // updating endTime so that contract doesn't remain active
        address winner;                                // initializing the address of the winning bidder
        for(uint i =0;i<biddersList.length;i++){        // for loop for checking the bids mapping using the biddersList array to check
            if(bids[biddersList[i]]==bid){              // for the bid value passed as argument
                winner = biddersList[i];
                break;
            }
        }
        require(winner!=address(0),"This bid has not been made");  // if bid entered is invalid
        return winner;
    }


    // function to return the maximum bid on the auction
    function getMaximumBid() external isActive view returns(uint){

        uint maxBid = 0;                                   // initializing the maxBid to store and return it
        for(uint i;i<biddersList.length;i++){              // for looping and checking all the bids to find the max bid
            maxBid = max(bids[biddersList[i]],maxBid);    // here we are using the max function defined on line 38
        }
        return maxBid;


    }


    ///////// MODIFIERS /////////////


    // to check if the auction is in active state or not by checking the endTime
    modifier isActive(){
        require(block.timestamp < endTime,"Auction is Inactive ");
        _;
    }

    // to check if bid is created by the address owner or not
    modifier isBidPresent(){
        require(bids[tx.origin]==0,"You have already created a bid");
        _;
    }

    // to check if bid value is greater than the minimum bid val specified by the auction
    modifier validBidVal(uint _bidVal){
        require(_bidVal > minBidVal,"Please enter a bid greater than minimum required bid of given auction");
        _;
    }

    // To check whether any bids are present before ending the auction
    modifier isBidsMade(){
        uint len = biddersList.length;
        require(len>0,"Can't end as no bids have been made yet");
        _;
    }



}