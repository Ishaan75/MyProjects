// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.24;


contract Auction{
    
    // the owner manages the smart contract
    address public owner;
    // start time of auction
    uint public startBlock;
    //  end time of auction
    uint public endBlock;
    
    enum State{Started,Running,Ended,Cancelled}
    State public auctionState;
    
    // selling price of highest binding bid
    uint public highestBindingBid;
    
    // highest bidder information
    address public highestBidder;
    
    // increment in bid each time
    uint public bidIncrement;
    
    mapping(address => uint ) public bids;
    
    constructor () public{
        
        owner = msg.sender;
        auctionState = State.Running;
        startBlock = block.number;
        
        // 1 block in ethereum takes 15 seconds to get mined
        endBlock = startBlock + 40320;// as auction runs for 1 week
        
        //increment in bid each time is int104
        bidIncrement = 10;
    }
    
    modifier onlyOwner(){
        
        require(msg.sender == owner);
        _;
    }
    modifier afterStart(){
        
        require(block.number>= startBlock);
        _;
    }
    modifier beforeEnd(){
        
        require(block.number <= endBlock);
        _;
    }
    // owner can not place a bid
    modifier noOwner(){
        
        require(msg.sender!=owner);
        _;
    }
    // whenever there is something wrong in the auction
    function cancel_auction() onlyOwner public{
        
        auctionState = State.Cancelled;
    }
    
    function min(uint a,uint b) pure internal returns(uint){
        
        if(a>=b){
            return b;
        }
        else{
            return a;
        }
    }
    function Place_bid() public payable noOwner afterStart beforeEnd returns(bool){
        
        require(auctionState==State.Running);
        
        // minimum of 0.01 ether is required for thr transaction
        require(msg.value >= 0.01 ether);
        
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid>highestBindingBid);
        bids[msg.sender] = currentBid;
        
        if(currentBid<=bids[highestBidder]){
            highestBindingBid = min(currentBid+bidIncrement , bids[highestBidder]);
        }
        else{
            highestBindingBid = min(currentBid,bids[highestBidder] + bidIncrement);
        }
        
        return true;
    }
    
    // if auction is ended 
    function finalAuction() onlyOwner public{
        require(auctionState == State.Cancelled || block.number >endBlock);
        require(bids[msg.sender]>0);
        
        address receipent;
        uint value;
        
        if(auctionState == State.Cancelled){
            receipent = msg.sender;
            value = bids[msg.sender];
            
        }
        else if(msg.sender ==  owner){
            // if auction is ended then only winner will get all the money which is none but owner
            receipent = owner;
            receipent.transfer(value);
        }
        else if(msg.sender == highestBidder){
            receipent = highestBidder;
            value  = bids[highestBidder] - highestBindingBid;
        }
        else{
             receipent = msg.sender;
             value = bids[msg.sender];
        }
        receipent.transfer(value);
    }
    
    
}
