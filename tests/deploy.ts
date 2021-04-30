const {TonClient} = require("@tonclient/core");
const {libNode} = require("@tonclient/lib-node");
const fs = require('fs');
import { expect } from "chai";
import { TonContract } from "./ton-contract";


const SimpleAuctionPack = require('./ton-packages/SimpleAuction.json');
const SimpleAuctionDutchPack = require('./ton-packages/DutchAuction.json');
const SimpleRootPack = require('./ton-packages/SimpleRoot.json');
const DebotPack = require('./ton-packages/debot/AuctionDebot.json');


// Setup SDK network
TonClient.useBinaryLibrary(libNode);
const client = new TonClient({
    network: { 
        server_address: 'http://net.ton.dev' 
    } 
});

describe('Deploy to devnet', () => {

    var Root;
    var RootKeys;

    var Debot;
    var DebotKeys;

    it("Setup keys and data", async () => {
        RootKeys = await client.crypto.generate_random_sign_keys();
        Root = new TonContract({
            client,
            name: "SimpleRoot",
            tonPackage: SimpleRootPack,
            keys: RootKeys,
        });
        await Root.init();

        DebotKeys = await client.crypto.generate_random_sign_keys();
        Debot = new TonContract({
            client,
            name: "Debot",
            tonPackage: DebotPack,
            keys: DebotKeys,
        });
        await Debot.init();
    })

    it("deploy Root", async () => {
        console.log("To process deploy please trunsfer funds to ",Root.address)
        await Root.deploy({
            input: { _CodeAuctionEnglish: SimpleAuctionPack.image, _CodeAuctionDutch: SimpleAuctionDutchPack.image},
        })
        let balance = await Root.getBalance()
        console.log("Root balance: ", balance)
        console.log("Root keys: ", RootKeys)
    })

    it("deploy DeBot", async () => {
        console.log("To process deploy please trunsfer funds to ",Debot.address)

        await Debot.deploy({ input: {
            Root: Root.address
        }, })

        await Debot.call({
            functionName: "setAbi",
            input: {
              debotAbi: Buffer.from( JSON.stringify(DebotPack.abi) ).toString("hex"),
            },
        });

        let balance = await Debot.getBalance()
        console.log("DeBot balance: ", balance)
        console.log("Debot keys: ", DebotKeys)
    })

})
