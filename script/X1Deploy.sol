// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/X1Coin.sol";
import "../src/X1Staking.sol";

contract X1Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address teamWallet = vm.envAddress("TEAM_WALLET");
        address communityWallet = vm.envAddress("COMMUNITY_WALLET");
        address publicSaleWallet = vm.envAddress("PUBLIC_SALE_WALLET");

        X1Coin token = new X1Coin(teamWallet, communityWallet, publicSaleWallet);

        X1CoinStaking staking = new X1CoinStaking(address(token));

        token.distributeTokens();

        vm.stopBroadcast();

        console.log("X1Coin deployed to:", address(token));
        console.log("Staking contract deployed to:", address(staking));
    }
}
