const fs = require('fs');

async function PackContract  (contract)  {
    try {
      let json = {name:'',abi:{},image:''}
      let tvcInBase64 = fs.readFileSync(`./contracts/${contract}.tvc`).toString('base64');
      let abi_json = JSON.parse(fs.readFileSync(`./contracts/${contract}.abi.json`).toString()); // require(`../contracts/${contract}.abi.json`);
      json.name = contract;
      json.abi = abi_json;
      json.image = tvcInBase64;
    
      fs.writeFileSync(`./tests/ton-packages/${contract}.json`, JSON.stringify(json), function(error){
        if(error) throw error; 
      })
    
      return true;
    } catch (err) {
      console.log(err);
    }
}



describe('Pack contracts', () => {
    console.log("PACKING");
    it('Pack contracts', async () => {
        PackContract('SimpleRoot');
        PackContract('SimpleAuction');
        //PackContract('SimpleWallet');
        PackContract('DutchAuction');
        PackContract('debot/AuctionDebot');
    });
});