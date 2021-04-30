const {TonClient} = require("@tonclient/core");
const {libNode} = require("@tonclient/lib-node");
const fs = require('fs');
import { expect } from "chai";
import { TonContract } from "./ton-contract";

const nseGiverPack = require('./ton-packages/nse-giver.json');
const SimpleAuctionPack = require('./ton-packages/SimpleAuction.json');
const SimpleAuctionDutchPack = require('./ton-packages/DutchAuction.json');
const SimpleRootPack = require('./ton-packages/SimpleRoot.json');
const SimpleWalletPack = require('./ton-packages/SimpleWallet.json');


// Setup SDK network
TonClient.useBinaryLibrary(libNode);
const client = new TonClient({
    network: { 
        server_address: 'http://localhost'  // 'net.ton.dev'
    } 
});

// Address of giver on TON OS SE
const giverAddress = '0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94';

describe('Common test', () => {

    var Root;
    var RootKeys;
    var nseGiver;

    var Auction;
    var AuctionAddr;

    var AuctionDutch;

    var SimpleWalletKeys;
    var SimpleWallet;

    it("Setup keys and data", async () => {
        RootKeys = await client.crypto.generate_random_sign_keys();
        Root = new TonContract({
            client,
            name: "SimpleRoot",
            tonPackage: SimpleRootPack,
            keys: RootKeys,
        });
        await Root.init();

        SimpleWalletKeys = await client.crypto.generate_random_sign_keys();
        SimpleWallet = new TonContract({
            client,
            name: "SimpleWallet",
            tonPackage: SimpleWalletPack,
            keys: SimpleWalletKeys,
        });
        await SimpleWallet.init();

        nseGiver = new TonContract({
            client,
            name: "nseGiver",
            tonPackage: nseGiverPack,
            keys: await client.crypto.generate_random_sign_keys(),
            address: giverAddress,
        });
    })


    it("deploy Root", async () => {
        
        let address = Root.address;
        await nseGiver.call({ functionName: "sendGrams", input: { amount: 100_000_000_000, dest: address } });
        console.log(`Tons were transfered from giver to ${address}`);
        await Root.deploy({
            input: { _CodeAuctionEnglish: SimpleAuctionPack.image, _CodeAuctionDutch: SimpleAuctionDutchPack.image},
        })
        let balance = await Root.getBalance()
        console.log("Root balance: ", balance)

        expect(balance).to.be.lessThan(100_000_000_000)
        expect(balance).not.to.be.equal(0)
        
    });

    it("deploy Auction", async () => {
        let auc = await Root.callKeys( { functionName: "CreateAuctionEnglish", input: {
            description: Buffer.from("Test").toString("hex"), startPrice: 900_000_000, auctionDuration: 7
        } }, SimpleWalletKeys )
        AuctionAddr = auc.decoded.output.addrAuction
        console.log("Auction address: ", AuctionAddr )

        Auction = new TonContract({
            client,
            name: "SimpleAuction",
            tonPackage: SimpleAuctionPack,
            keys: RootKeys,
            address: AuctionAddr,
        });

    });

    it("test Auction", async () => {
        let a = await Auction.callLocal( { functionName: "Deployer", input: {} }) ;
        console.log(a)
        expect(a.value.Deployer).to.be.equal(Root.address);
    });

    it("deploy Wallet", async () => {
        let address = SimpleWallet.address;
        await nseGiver.call({ functionName: "sendGrams", input: { amount: 100_000_000_000, dest: address } });
        console.log(`Tons were transfered from giver to ${address}`);
        await SimpleWallet.deploy({
            input: {},
        })
        let balance = await SimpleWallet.getBalance()
        console.log("SimpleWallet balance: ", balance)
        expect(balance).to.be.lessThan(100_000_000_000)
        expect(balance).not.to.be.equal(0)
    });


    it("Try to set Bid", async () => {
        let a = await SimpleWallet.call( { functionName: "sendTransaction", input: {dest: AuctionAddr, value: 1_000_000_000, bounce:false} }) ;
        console.log(a)

        let b = await Auction.callLocal( { functionName: "firstBid", input: {} }) ;
        console.log(b)
        expect(b.value.firstBid.addr).to.be.equal(SimpleWallet.address);

        console.log("Wallet balance: ", await SimpleWallet.getBalance() )

        await SimpleWallet.call( { functionName: "sendTransaction", input: {dest: AuctionAddr, value: 4_000_000_000, bounce:false} })
        console.log("Wallet balance: ", await SimpleWallet.getBalance() )

        await SimpleWallet.call( { functionName: "sendTransaction", input: {dest: AuctionAddr, value: 2_000_000_000, bounce:false} })
        console.log("Wallet balance: ", await SimpleWallet.getBalance() )
    })

    it("Finish auction", async () => {
        let e = await Auction.callLocal( { functionName: "TimeToEnd", input: {} }) ;
        console.log(e)

        // Wait for auction time to end
        while( (await Auction.callLocal( { functionName: "TimeToEnd", input: {} })).value.value0 > 0 ) {}

        console.log("Wallet balance: ", await SimpleWallet.getBalance() )
        console.log("Root balance: ", await Root.getBalance() )
        console.log("Auction balance: ", await Auction.getBalance() )

        let f = await Auction.call( { functionName: "Finish", input: {} }) ;
        //console.log(f)

        let c = await Auction.callLocal( { functionName: "isCompleted", input: {} }) ;
        console.log(c)
        expect(c.value.isCompleted).to.be.equal(true);
        

        console.log("Wallet balance: ", await SimpleWallet.getBalance() )
        console.log("Root balance: ", await Root.getBalance() )
        console.log("Auction balance: ", await Auction.getBalance() )
        
        let w = await Auction.callKeys( { functionName: "Withdraw", input: {dest: Root.address} }, SimpleWalletKeys) ;
        console.log(w)

        console.log("Wallet balance: ", await SimpleWallet.getBalance() )
        console.log("Root balance: ", await Root.getBalance() )
        console.log("Auction balance: ", await Auction.getBalance() )

        console.log("", await Auction.callLocal( { functionName: "GetInfo", input: {} }))
    })
    
    

})