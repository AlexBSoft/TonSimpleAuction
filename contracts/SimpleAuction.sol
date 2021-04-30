pragma ton-solidity >= 0.36.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

/*
Simple English Auction

Error codes

400 - Auction not ended yet
401 - Auction not finished yet. Call finish() first
402 - You not owner or deployer of this auction

*/

interface ISimpleRoot {
    function _auctionFinished() external ;
}

contract SimpleAuction {

    address static public Deployer;
    string static public Description;

    bytes public ExtraData;

    uint public Owner;
    uint128 public StartPrice;
    bool public isCompleted;
    uint public auctionDuration;
    uint public auctionEndTime;

    struct Bid{
        address addr;
        uint pubKey;
        uint128 value;
    }

    Bid public firstBid;
    Bid public secondBid;

    uint8 public AuctionType = 1; // English auction


    constructor(uint _Owner, uint128 _StartPrice, uint _auctionDuration) public {
        tvm.accept();
        Owner = _Owner;
        StartPrice = _StartPrice;
        auctionDuration = _auctionDuration;
        auctionEndTime = now+_auctionDuration;
    }

    event BidRefund(address, uint128);
    event BidNotAccepted(address, uint128);
    event BidPlaced(address, uint128);
    event AuctionFinished(address, uint128, address);

    /*
    On money recieved - place or update bid
    */
    receive() external {
        //tvm.accept();

        if( now >= auctionEndTime && firstBid.value >= StartPrice){
            Finish();
            emit BidNotAccepted(msg.sender,msg.value);
            address(msg.sender).transfer(msg.value, false, 1);
        }

        if(!isCompleted && now < auctionEndTime )
            _placeBid(msg.sender, msg.pubkey(), msg.value);
        // Maybe refund if auction is completed?
	}


    /*
    Local place bid
    */
    function _placeBid(address bidder, uint pubkey, uint128 value) internal {
        Bid b1 = firstBid;
        Bid b2 = secondBid;
        Bid newBid = Bid(bidder, pubkey, value);

        // Bet highest bid
        if(value > b1.value && value >= StartPrice){
            firstBid = newBid;
            secondBid = b1;
            emit BidPlaced(newBid.addr, newBid.value);
            // Refund second bid
            emit BidRefund(b2.addr, b2.value);
            address(b2.addr).transfer(b2.value, false);
        }
        // Bet second bid
        else if(value > b2.value && value >= StartPrice){
            secondBid = newBid;
            emit BidPlaced(newBid.addr, newBid.value);
            // Refund second bid
            emit BidRefund(b2.addr, b2.value);
            address(b2.addr).transfer(b2.value, false);
        }
        // No bid bet
        else {
            emit BidNotAccepted(newBid.addr, newBid.value);
            address(newBid.addr).transfer(newBid.value, false);
        }
    }
 
    /*
    Finish auction when time auctionEndTime
    */
    function Finish() public {
        require(now >= auctionEndTime, 400, "Auction not ended yet");
        tvm.accept();
        isCompleted = true;
        // Refund 2 bid
        if(secondBid.value >= StartPrice){
            emit BidRefund(secondBid.addr, secondBid.value);
            address(secondBid.addr).transfer(secondBid.value, false);
        }

        emit AuctionFinished(firstBid.addr, firstBid.value, msg.sender);
        ISimpleRoot(Deployer)._auctionFinished();

        /*
        Perform some actions here
        */

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
        address(dest).transfer( address(this).balance , false, 128);
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
        Bid _firstBid, Bid _secondBid, bool _isCompleted, uint128 _StartPrice, string _Description, uint _auctionDuration, uint _auctionEndTime, int _TimeToEnd
    ){
        _firstBid = firstBid;
        _secondBid = secondBid;
        _isCompleted = isCompleted;
        _StartPrice = StartPrice;
        _Description = Description;
        _auctionDuration = auctionDuration;
        _auctionEndTime = auctionEndTime;
        _TimeToEnd = int(auctionEndTime) - int(now);
    }

}