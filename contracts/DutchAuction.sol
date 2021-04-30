pragma ton-solidity >= 0.36.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

/*
Simple Dutch Auction

Error codes

400 - Auction not ended yet
401 - Auction not finished yet. Call finish() first
402 - You not owner or deployer of this auction
403 - Value is too high
404 - You owner of this auction
405 - Not enough money
406 - Auction is end
*/

interface ISimpleRoot1 {
    function _auctionFinished() external ;
}

contract DutchAuction{
    address static public Deployer;
    string static public Description;

    bytes public ExtraData;

    uint public Owner;
    uint128 public StartPrice;
    uint128 public CurrentPrice;
    uint128 private MinPrice; 
    bool public isCompleted;
    uint public auctionDuration;
    uint public auctionEndTime;

    uint8 public AuctionType = 2; // Dutch auction

    struct Bid{
        address addr;
        uint pubKey;
        uint128 value;
    }
    Bid public firstBid;

    constructor(uint _Owner, uint128 _StartPrice, uint128 _MinPrice, uint _auctionDuration) public {
        tvm.accept();
        Owner = _Owner;
        StartPrice = _StartPrice;
        CurrentPrice = _StartPrice;
        MinPrice = _MinPrice;
        auctionDuration = _auctionDuration;
        auctionEndTime = now + _auctionDuration;
    }

    event PriceReduced(uint128); 
    event PriceMin(uint128); // Price reached min
    event BidRefund(address, uint128);
    event BidNotAccepted(address, uint128);
    event BidPlaced(address, uint128);
    event BidAccepted(address, uint128); 
    event AuctionFinished(address, uint128, address);

    /*
    On money recieved - place bid
    */
    receive() external{
        if( now >= auctionEndTime){
            Finish();
            emit BidNotAccepted(msg.sender,msg.value);
            address(msg.sender).transfer(msg.value, false, 1);
        }else{
            _acceptBid(msg.sender, msg.pubkey(), msg.value);
        }
    }

    /*
    Reduce price by value
    */
    function ReducePrice(uint128 value) public{
        require(msg.pubkey() == Owner, 402, "You not owner of this auction");
        require(CurrentPrice - value >= MinPrice, 403, "Value is too high");
        tvm.accept();
        if(CurrentPrice - value > MinPrice){
            CurrentPrice -= value;
            emit PriceReduced(CurrentPrice);
        }
        else if (CurrentPrice - value == MinPrice){
            CurrentPrice = MinPrice;
            emit PriceMin(CurrentPrice);
        }
    }

    /*
    Recieve money & Finish auction
    */
    function _acceptBid(address bidder, uint pubkey, uint128 value) internal {
        require(pubkey != Owner, 404, "You owner of this auction");
        require(value >= CurrentPrice, 405, "Not enough money");
        require(!isCompleted, 406, "Auction is ended");
        tvm.accept();
        
        firstBid = Bid(bidder,pubkey,value);

        isCompleted = true;
        emit BidAccepted(bidder,value);
        Finish();
    }

    /*
    Withdraw seller money after auction finished
    */
    function Withdraw(address dest) public {
        require(isCompleted , 401, "Auction not finished yet. Call finish() first");
        require(msg.pubkey() == Owner || msg.sender == Deployer, 402, "You not owner or deployer of this auction");
        tvm.accept();

        // Pay fee to Root
        //address(Deployer).transfer( 1 ton , false, 0);

        // Send all money to seller
        //address(dest).transfer( address(this).balance , false, 1);
        address(dest).transfer(address(this).balance , false, 128);
    }

    function Finish() public {
        require(now >= auctionEndTime || isCompleted, 400, "Auction not ended yet");
        tvm.accept();
        
        emit AuctionFinished(firstBid.addr, firstBid.value, msg.sender);
        ISimpleRoot1(Deployer)._auctionFinished();

        /*

        Perform some actions here

        */

    }

    /*

    View functions

    */

    /*
    Get the remaining time
    */
    function TimeToEnd() public view returns (int){
        tvm.accept();
        return int(auctionEndTime) - int(now);
    }
    /*
    Get all auction info
    */
    function GetInfo() external view returns
    (
        bool _isCompleted, uint128 _StartPrice, string _Description, uint _auctionDuration, uint _auctionEndTime, int _TimeToEnd
    ){
        _isCompleted = isCompleted;
        _StartPrice = StartPrice;
        _Description = Description;
        _auctionDuration = auctionDuration;
        _auctionEndTime = auctionEndTime;
        _TimeToEnd = int(auctionEndTime) - int(now);
    }
}