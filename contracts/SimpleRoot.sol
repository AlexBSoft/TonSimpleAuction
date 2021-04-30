pragma ton-solidity >= 0.36.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./SimpleAuction.sol";
import "./DutchAuction.sol";


contract SimpleRoot {

    TvmCell CodeAuctionEnglish;
    TvmCell CodeAuctionDutch;

    mapping(address => bool) public AuctionsState;

    constructor(TvmCell _CodeAuctionEnglish, TvmCell _CodeAuctionDutch) public {
        tvm.accept();
        CodeAuctionEnglish = _CodeAuctionEnglish;
        CodeAuctionDutch = _CodeAuctionDutch;
    }

    event auctionDeployed(address addrAuction);
    event auctionFinished(address addrAuction);


    function CreateAuctionEnglish(string description, uint128 startPrice, uint auctionDuration) public returns (address addrAuction){
        tvm.accept();
        TvmCell state = _buildAuctionStateEnglish(description);
        
        addrAuction = new SimpleAuction{
            stateInit: state,
            value: 1 ton
        }(
            msg.pubkey(),
            startPrice,
            auctionDuration
        );

        AuctionsState[addrAuction] = false;
        emit auctionDeployed(addrAuction);
    }

    function CreateAuctionDutch(string description, uint128 startPrice, uint128 minPrice, uint auctionDuration) public returns (address addrAuction){
        tvm.accept();
        TvmCell state = _buildAuctionStateDutch(description);

        addrAuction = new DutchAuction{
            stateInit: state,
            value: 1 ton
         }(
            msg.pubkey(),
            startPrice,
            minPrice,
            auctionDuration
        );

        AuctionsState[addrAuction] = false;
        emit auctionDeployed(addrAuction);
    }

    function ResolveAuctionEnglish(string description) public view returns (address addrAuction) {
        tvm.accept();
        TvmCell state = _buildAuctionStateEnglish(description);
        uint256 hashState = tvm.hash(state);
        addrAuction = address.makeAddrStd(0, hashState);
    }

    function ResolveAuctionDutch(string description) public view returns (address addrAuction) {
        tvm.accept();
        TvmCell state = _buildAuctionStateDutch(description);
        uint256 hashState = tvm.hash(state);
        addrAuction = address.makeAddrStd(0, hashState);
    }

    function _buildAuctionStateEnglish(string _Description) internal view returns(TvmCell){
        tvm.accept();
        TvmCell _CodeAuction;
        _CodeAuction = CodeAuctionEnglish.toSlice().loadRef();

        return tvm.buildStateInit({
            contr: SimpleAuction,
            varInit: {Deployer: address(this), Description: _Description},
            code: _CodeAuction
        });
    }
    
    function _buildAuctionStateDutch(string _Description) internal view returns(TvmCell){
        tvm.accept();
        TvmCell _CodeAuction;
        _CodeAuction = CodeAuctionDutch.toSlice().loadRef();

        return tvm.buildStateInit({
            contr: SimpleAuction,
            varInit: {Deployer: address(this), Description: _Description},
            code: _CodeAuction
        });
    }

    /*
        Function called by Auction when its finished

        Modify this function as you need
    */
    function _auctionFinished() external {
        require(AuctionsState.exists(msg.sender), 110, "No such Auction");
        tvm.accept();
        AuctionsState[msg.sender] = true;
        emit auctionFinished(msg.sender);
        /*
        Perform some actions here
        */
    }

    function Withdraw(address dest) public {
        require(msg.pubkey() == tvm.pubkey(), 100, "You not owner");
        tvm.accept();
        address(dest).transfer( address(this).balance , false, 128);
    }

}