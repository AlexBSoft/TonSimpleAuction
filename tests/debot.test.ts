const {TonClient} = require("@tonclient/core");
const {libNode} = require("@tonclient/lib-node");
const fs = require('fs');
import { expect } from "chai";
import { TonContract } from "./ton-contract";

const nseGiverPack = require('./ton-packages/nse-giver.json');
const SimpleAuctionPack = require('./ton-packages/SimpleAuction.json');
const SimpleRootPack = require('./ton-packages/SimpleRoot.json');
const SimpleWalletPack = require('./ton-packages/SimpleWallet.json');
const DebotPack = require('./ton-packages/debot/AuctionDebot.json');


// Setup SDK network
TonClient.useBinaryLibrary(libNode);
const client = new TonClient({
    network: { 
        server_address: 'http://localhost'  // 'net.ton.dev'
    } 
});

// Address of giver on TON OS SE
const giverAddress = '0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94';

describe('DeBot test', () => {
    var Debot;
    var DebotKeys;
    var nseGiver;

    it("SetupContracts", async () => {
        DebotKeys = await client.crypto.generate_random_sign_keys();
        Debot = new TonContract({
            client,
            name: "Debot",
            tonPackage: DebotPack,
            keys: DebotKeys,
        });
        await Debot.init();

        nseGiver = new TonContract({
            client,
            name: "nseGiver",
            tonPackage: nseGiverPack,
            keys: await client.crypto.generate_random_sign_keys(),
            address: giverAddress,
        });
    })
    it("DeployDebot", async () => {
        let address = Debot.address;
        console.log(address)
        await nseGiver.call({ functionName: "sendGrams", input: { amount: 10_000_000_000, dest: address } });
        console.log(`Tons were transfered from giver to ${address}`);

        await Debot.deploy({ input: {
            Root: "0:476da9b62c4a04a1e88f44949bcffa792b420cd1386401008c60ea3405f1a435" // Change it here!
        }, })

        await Debot.call({
            functionName: "setAbi",
            input: {
              debotAbi: Buffer.from( JSON.stringify(DebotPack.abi) ).toString("hex"),
            },
        });

        let balance = await Debot.getBalance()
        console.log("DeBot balance: ", balance)

        expect(balance).to.be.lessThan(100_000_000_000)
        expect(balance).not.to.be.equal(0)
    })

})