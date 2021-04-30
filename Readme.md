# Simple TON Auction

This project implements simplified English & Dutch Auctions if Free TON smart contracts.

System consists of 3 contracts:

- SimpleRoot (aka Auction deployer)
- SimpleAuction (Auction itself)
- DeBot (Auction iterface)

Sample Root in Devnet
`0:0eb6fef10aa7f2496c8f43c5b120ae01a2f0661508184b98b9b0c8f44052b709`

Sample DeBot in Devnet
`0:ed64f712d1c8e263cbaf338944f1a78e8beaa3acc5534c57e759471a342a4868`

### SimpleRoot

Setup Auction contract image in constructor while deploying contract.

Call `CreateAuction(description, startPrice, auctionDuration)` to deploy new Auction contract. Returns Auction address.

### English auction

It is default auction type in `SimpleAuction.sol`

Bids should be made directly by transfering funds to Auction contract. Auction stores 2 latest bids and automaticully refunds previous bids.

Once auction is finished it can deploy new contract or perform any action, the system is flexible and easy to modify.

#### Commands:

- Money transfer - place Bid
- `Finish()` - mark auction as finished. Call this function when time for bids ended
- `Withdraw(address dest)` - withdraw the earned amount

### Dutch auction (reversed auction)

It is optional partially implemented auction type in `DutchAuction.sol`

In this type of auction, seller should lower price until somebody places bid.

Bids are submitted in the same way as in the English auction, via common transfers.

Auction created with `StartPrice` and `MinPrice`.
`MinPrice` - the minimum price to which the bid price can drop.

#### Commands:
- Money transfer - place Bid
- `ReducePrice(value)` - reduce price by amount
- `Finish()` - mark auction as finished. Call this function when time for bids ended
- `Withdraw(address dest)` - withdraw the earned amount

## Tests

Tests are made using mocha. To run project on local Node SE:

- Start docker with tonos
- Compile contracts (easiest way is to use TONDev extension in VS Code, jsut right click on .sol files and click Compile)
- Pack contracts `test:pack`
- Run tests `test:common`

## DeBot

DeBot allows users to interact with Auctions and deploy new Auctions.

DeBot is not finished yet, but you still can create new auctions using it.

### Deploy DeBot

- Change Root address in file debot.test.ts
- Compile & pack contracts
- Run `test:debot`

### Use DeBot

- Connect to it using `tonos-cli --url http://127.0.0.1 debot fetch <addr>`
- Create new Auction (press 2)
- Enter all data
- Interact with auction (press 1)

## Deploy

- Compile contracts (easiest way is to use TONDev extension in VS Code, jsut right click on .sol files and click Compile)
- Pack contracts `test:pack`
- Deploy to devnet `test:deploy`
- Follow instruction in console:
    - Transfer funds to Root address
    - Transfer funds to DeBot address
- Save keys & you are breathtaking
