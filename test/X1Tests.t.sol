// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {X1Coin} from "../src/X1Coin.sol";
import {X1CoinStaking} from "../src/X1Staking.sol";

contract X1CoinTest is Test {
    X1Coin public token;
    X1CoinStaking public staking;

    address public owner;
    address public teamWallet;
    address public communityWallet;
    address public publicSaleWallet;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        teamWallet = address(0x1);
        communityWallet = address(0x2);
        publicSaleWallet = address(0x3);
        user1 = address(0x4);
        user2 = address(0x5);

        token = new X1Coin(teamWallet, communityWallet, publicSaleWallet);
        staking = new X1CoinStaking(address(token));

        token.distributeTokens();

        vm.startPrank(publicSaleWallet);
        token.transfer(user1, 10000 * 10 ** 18);
        token.transfer(user2, 10000 * 10 ** 18);
        token.transfer(address(this), 10000 * 10 ** 18);

        vm.stopPrank();

        token.approve(address(staking), 10000 * 10 ** 18);
        staking.addRewardTokens(1000 * 10 ** 18);

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testTransfer() public {
        vm.startPrank(user1);
        uint256 initialBalance = token.balanceOf(user2);
        uint256 transferAmount = 100 * 10 ** 18;

        token.transfer(user2, transferAmount);
        assertEq(token.balanceOf(user2), initialBalance + transferAmount);
        assertEq(token.balanceOf(user1), 10000 * 10 ** 18 - transferAmount);
        vm.stopPrank();
    }

    function testApproveAndTransferFrom() public {
        vm.startPrank(user1);
        uint256 approvalAmount = 500 * 10 ** 18;

        token.approve(user2, approvalAmount);
        assertEq(token.allowance(user1, user2), approvalAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        token.transferFrom(user1, address(this), approvalAmount);
        assertEq(token.allowance(user1, user2), 0);
        assertEq(token.balanceOf(address(this)), 9000 * 10 ** 18 + approvalAmount);
        vm.stopPrank();
    }

    function testFailTransferInsufficientBalance() public {
        vm.startPrank(user1);
        uint256 excessAmount = 20000 * 10 ** 18;
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        token.transfer(user2, excessAmount);
        vm.stopPrank();
    }

    function testInitialDistribution() public view {
        assertEq(token.totalSupply(), 1_000_000_000 * 10 ** 18);
        assertEq(token.balanceOf(publicSaleWallet) + 30000 * 10 ** 18, token.PUBLIC_SALE_AMOUNT());
        assertEq(token.balanceOf(communityWallet), token.COMMUNITY_AMOUNT());
        assertEq(token.balanceOf(address(token)), token.TEAM_ADVISOR_AMOUNT());
    }

    function testTeamTokenVesting() public {
        vm.expectRevert();
        token.releaseTeamTokens();

        vm.warp(block.timestamp + 180 days);
        token.releaseTeamTokens();

        assertEq(token.balanceOf(teamWallet), token.TEAM_ADVISOR_AMOUNT());

        vm.expectRevert();
        token.releaseTeamTokens();
    }

    function testVestingTimelock() public {
        uint256 preReleaseBalance = token.balanceOf(teamWallet);

        vm.warp(block.timestamp + 179 days);
        vm.expectRevert();
        token.releaseTeamTokens();
        assertEq(token.balanceOf(teamWallet), preReleaseBalance);
    }

    function testStakingBasics() public {
        vm.startPrank(user1);
        uint256 stakeAmount = 500 * 10 ** 18;
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);

        (uint256 stakedAmount, uint256 startTime,) = staking.getStakeInfo(user1);
        assertEq(stakedAmount, stakeAmount);
        assertEq(startTime, block.timestamp);
        assertEq(token.balanceOf(address(staking)), 1500 * 10 ** 18);
        vm.stopPrank();
    }

    function testMultipleStakes() public {
        vm.startPrank(user1);
        token.approve(address(staking), 1000 * 10 ** 18);
        staking.stake(400 * 10 ** 18);
        staking.stake(600 * 10 ** 18);

        (uint256 stakedAmount,,) = staking.getStakeInfo(user1);
        assertEq(stakedAmount, 1000 * 10 ** 18);
        vm.stopPrank();
    }

    function testStakingPeriodEnforcement() public {
        vm.startPrank(user1);
        token.approve(address(staking), 500 * 10 ** 18);
        staking.stake(500 * 10 ** 18);

        vm.expectRevert();
        staking.unstake();

        vm.warp(block.timestamp + 29 days);
        vm.expectRevert();
        staking.unstake();

        vm.warp(block.timestamp + 2 days);
        staking.unstake();
        vm.stopPrank();
    }

    function testRewardCalculation() public {
        vm.startPrank(user1);
        uint256 stakeAmount = 1000 * 10 ** 18;
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);

        vm.warp(block.timestamp + 182 days);
        (,, uint256 halfYearRewards) = staking.getStakeInfo(user1);
        assertApproxEqRel(halfYearRewards, 50 * 10 ** 18, 1e16);

        vm.warp(block.timestamp + 183 days);
        (,, uint256 fullYearRewards) = staking.getStakeInfo(user1);
        assertApproxEqRel(fullYearRewards, 100 * 10 ** 18, 1e16);
        vm.stopPrank();
    }

    function testRewardClaiming() public {
        vm.startPrank(user1);
        token.approve(address(staking), 1000 * 10 ** 18);
        staking.stake(1000 * 10 ** 18);

        vm.warp(block.timestamp + 365 days);
        uint256 initialBalance = token.balanceOf(user1);

        staking.claimRewards();
        uint256 finalBalance = token.balanceOf(user1);

        assertApproxEqRel(finalBalance - initialBalance, 100 * 10 ** 18, 1e16);

        (,, uint256 remainingRewards) = staking.getStakeInfo(user1);
        assertEq(remainingRewards, 0);
        vm.stopPrank();
    }

    function testEmergencyControls() public {
        staking.pause();

        vm.startPrank(user1);
        token.approve(address(staking), 100 * 10 ** 18);
        vm.expectRevert();
        staking.stake(100 * 10 ** 18);

        vm.stopPrank();

        staking.unpause();

        vm.startPrank(user1);
        staking.stake(100 * 10 ** 18);
        vm.stopPrank();
    }

    function testStakingWithMultipleUsers() public {
        vm.startPrank(user1);
        token.approve(address(staking), 500 * 10 ** 18);
        staking.stake(500 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(staking), 300 * 10 ** 18);
        staking.stake(300 * 10 ** 18);
        vm.stopPrank();

        vm.warp(block.timestamp + 365 days);

        (,, uint256 user1Rewards) = staking.getStakeInfo(user1);
        (,, uint256 user2Rewards) = staking.getStakeInfo(user2);

        assertApproxEqRel(user1Rewards, 50 * 10 ** 18, 1e16);
        assertApproxEqRel(user2Rewards, 30 * 10 ** 18, 1e16);
    }
}
