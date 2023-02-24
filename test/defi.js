//jshint esversion:8
const { assert } = require("chai");
const Defi = artifacts.require("Defi");
const TUFToken = artifacts.require("TUFToken");
const Gate = artifacts.require("Gate");

contract("Defi", (accounts) => {

   const owner = accounts[0];
   const user = accounts[1];


   it("Stake the tokens", async () => {
      const defi = await Defi.deployed();
      const tufToken = await TUFToken.deployed();

      const userBal1 = await tufToken.balanceOf(user);
      assert(userBal1, 0);
      const userAll1 = await tufToken.allowance(user, defi.address);
      assert(userAll1, 0);

      await tufToken.transfer(user, '100000000000000000000', { from: owner });
      await tufToken.approve(defi.address, '100000000000000000000', { from: user });

      const userBal2 = await tufToken.balanceOf(user);
      assert(userBal2, '100000000000000000000');
      const userAll2 = await tufToken.allowance(user, defi.address);
      assert(userAll2, '100000000000000000000');

      const result = await defi.stakeTokens('100000000000000000000', tufToken.address, { from: user });
      console.log(result);

      const result1 = await defi.stakes(1);
      console.log(result1);
   });

  it("Unstake the tokens", async ()=>{
      const defi = await Defi.deployed();
      const tufToken = await TUFToken.deployed();

     setTimeout(async() => {
      await defi.unstakeTokens(1,{from: user});
      const result = await tufToken.balanceOf(user);
      assert(result, '100000000000000000000');
      await tufToken.transfer(owner, '100000000000000000000', { from: user });
      const result1 = await tufToken.balanceOf(defi.address);
      assert(result1, '0');
      const result2 = await tufToken.balanceOf(user);
      assert(result2,'0');
      console.log(result2);
      const result3 = await defi._calculateReward(1);
      console.log(result3);
  },60000);
     });

     it("Giving Reward Tokens", async()=>{
      const defi = await Defi.deployed();
      const tufToken = await TUFToken.deployed();

      await defi.claimRewardTokens(1,{from:owner});
      await tufToken.mint(user,'1000000000000000000');
      assert(result , '1000000000000000000');
     });

     it("claiming the NFT", async()=> {
      const defi = await Defi.deployed();
      const nft = await Gate.deployed();
      setTimeout(async()=>{
         await defi.claimNFTReward(1);
         const result = await nft.safeMint(user);
         assert(result);
      },120000);
      
     });
});