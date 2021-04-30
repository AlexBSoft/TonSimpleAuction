pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;
import "./Debot.sol";
import "./Terminal.sol";
import "./AddressInput.sol";
import "./AmountInput.sol";
import "./NumberInput.sol";
import "./ConfirmInput.sol";
import "./Sdk.sol";
import "./Menu.sol";
import "../Upgradable.sol";

struct Bid{
    address addr;
    uint pubKey;
    uint128 value;
}

interface IAuctionRoot {
    function CreateAuctionEnglish(string description, uint128 startPrice, uint auctionDuration) external returns (address addrAuction);
}

interface ISimpleAuction {
    
    function firstBid() external view returns(Bid);
    function secondBid() external view returns(Bid);
    function isCompleted() external view returns(bool);
    function Finish() external;
    function Withdraw(address dest) external;
    function GetInfo() external view returns
    (
        Bid _firstBid, Bid _secondBid, bool _isCompleted, uint128 _StartPrice, string _Description, uint _auctionDuration, uint _auctionEndTime, int _TimeToEnd
    );
}

contract AuctionDebot is Debot, Upgradable {

    address _addrAuctionRoot;
    address _addrAuction;
    address _addrMultisig;
    uint128 _amount;
    uint256 _salt;
    bytes m_icon;

    struct _NewAucData{
        string description;
        uint128 startPrice;
        uint duration;
    }

    constructor (address Root) public {
        tvm.accept();
        _addrAuctionRoot = Root;
    }

    _NewAucData _newAucData;

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
    function setAbi(string debotAbi) public {
        require(tvm.pubkey() == msg.pubkey(), 100);
        tvm.accept();
        m_options |= DEBOT_ABI;
        m_debotAbi = debotAbi;
    }

    
    

    function setIcon(bytes icon) public {
        require(msg.pubkey() == tvm.pubkey(), 100);
        tvm.accept();
        m_icon = icon;
    }

    function _version(uint24 major, uint24 minor, uint24 fix) private pure inline returns (uint24) {
        return (major << 16) | (minor << 8) | (fix);
    }

    function getVersion() public returns (string name, uint24 semver) {
        (name, semver) = ("Auction DeBot", _version(1,0,0));
    }


    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "SimpleAuctionDebot";
        version = "0.0.1";
        publisher = "Unknown";
        key = "Interact with Simple Auction here";
        author = "Unknown";
        support = address.makeAddrStd(0, 0);
        hello = "Hello, i am a Simple Auction DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function start() public override {
        Terminal.print(0, "Sell things! Buy things!");
        _start();
    }

    function _start() private {
        Menu.select(
        "What do you want to do?",
        "",
        [
            MenuItem("I know auction address", "", tvm.functionId(askAuctionAddress)),
            MenuItem("I want to create new auction", "", tvm.functionId(newAuction)),
            MenuItem("I want to browse open auctions", "", 0) // TODO
        ]
        );
    }

    function askAuctionAddress(uint32 index) public {
        index;
        AddressInput.get(tvm.functionId(entAuctionAddress), "Send Auction address (not Root)");
    }
    function entAuctionAddress(address value) public {
        _addrAuction = value;
        
        ISimpleAuction(value).GetInfo{
            abiVer: 2,
            extMsg: true,
            callbackId: tvm.functionId(onAuctionInfo),
            onErrorId: 0,
            time: 0,
            expire: 0,
            sign: false,
            pubkey: 0
        }();
    }
    function onAuctionInfo(Bid _firstBid, Bid _secondBid,  bool _isCompleted,  uint128 _StartPrice, string _Description, uint _auctionDuration, uint _auctionEndTime, int _TimeToEnd) public {
        if(_isCompleted){
            Terminal.print(0, "This auction is completed");
            //Bid winner = ISimpleAuction(value).firstBid();
            Terminal.print(0, format("Winner: {}, Price: {}", _firstBid.addr, _firstBid.value));
            
        }else{
            //int toEnd = ISimpleAuction(value).TimeToEnd();
            Terminal.print(0, format("Auction will end in {} sec", _TimeToEnd) );
            Menu.select(
            "What do you want to do?",
            "",
            [
                MenuItem("Place bid", "", tvm.functionId(aucPlaceBid)),
                MenuItem("Finish", "", tvm.functionId(aucFinish)),
                MenuItem("Withdraw", "", tvm.functionId(aucWithdraw))
            ]
            );
        }
    }

    function aucPlaceBid(uint32 index) public {

    }
    function aucFinish(uint32 index) public {
        
    }
    function aucWithdraw(uint32 index) public {
        
    }

    function newAuction(uint32 index) public {
        Terminal.input(tvm.functionId(newAuction2), "Enter name (description):", false);
    }
    function newAuction2(string value) public {
        _newAucData.description = value;
        AmountInput.get(tvm.functionId(newAuction3), "Type Start Price", 9, 1000000000, 1000000000000000);

    }
    function newAuction3(uint128  value) public {
        _newAucData.startPrice = value;
        Terminal.input(tvm.functionId(newAuction4), "Enter Duration (sec):", false);
        
    }
    function newAuction4(string value) public {
        optional(uint256) pubkey = 0;
    
        (_newAucData.duration,) = stoi(value);


        IAuctionRoot(_addrAuctionRoot).CreateAuctionEnglish{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(onNewAucSuccess),
            onErrorId: tvm.functionId(onNewAucError)
        }
        (_newAucData.description, _newAucData.startPrice, _newAucData.duration);
    }

    function onNewAucSuccess(address addrAuction) public {
        Terminal.print(0, "Auction created with address:" );
        Terminal.print(0, format("{}", addrAuction) );
    }

    function onNewAucError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
    }


    function _checkActiveStatus(int8 acc_type, string obj) private returns (bool) {
        if (acc_type == -1)  {
        Terminal.print(0, obj + " is inactive");
        return false;
        }
        if (acc_type == 0) {
        Terminal.print(0, obj + " is uninitialized");
        return false;
        }
        if (acc_type == 2) {
        Terminal.print(0, obj + " is frozen");
        return false;
        }
        return true;
    }
}

