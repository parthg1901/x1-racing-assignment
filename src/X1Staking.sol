// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract X1CoinStaking is ReentrancyGuard, Pausable, Ownable {
    IERC20 public immutable x1Token;
    uint256 public constant MINIMUM_STAKING_PERIOD = 30 days;
    uint256 public constant ANNUAL_REWARD_RATE = 10;
    
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastRewardCalculation;
        uint256 pendingRewards;
    }
    
    mapping(address => StakeInfo) public stakes;
    
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    
    constructor(address _x1Token) Ownable(msg.sender) {
        require(_x1Token != address(0), "Invalid token address");
        x1Token = IERC20(_x1Token);
    }

    function addRewardTokens(uint256 amount) external {
        require(x1Token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
    
    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Cannot stake 0 tokens");
        _updateRewards(msg.sender);
        require(x1Token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        stakes[msg.sender].amount += amount;
        if (stakes[msg.sender].startTime == 0) {
            stakes[msg.sender].startTime = block.timestamp;
            stakes[msg.sender].lastRewardCalculation = block.timestamp;
        }
        emit Staked(msg.sender, amount);
    }
    
    function unstake() external nonReentrant {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No tokens staked");
        require(block.timestamp >= userStake.startTime + MINIMUM_STAKING_PERIOD, "Minimum staking period not met");
        
        _updateRewards(msg.sender);
        uint256 amount = userStake.amount;
        uint256 rewards = userStake.pendingRewards;
        
        userStake.amount = 0;
        userStake.startTime = 0;
        userStake.pendingRewards = 0;
        userStake.lastRewardCalculation = 0;
        
        require(x1Token.transfer(msg.sender, amount), "Transfer failed");
        if (rewards > 0) {
            require(x1Token.transfer(msg.sender, rewards), "Rewards transfer failed");
            emit RewardsClaimed(msg.sender, rewards);
        }
        emit Unstaked(msg.sender, amount);
    }
    
    function claimRewards() external nonReentrant whenNotPaused {
        _updateRewards(msg.sender);
        uint256 rewards = stakes[msg.sender].pendingRewards;
        require(rewards > 0, "No rewards to claim");
        
        stakes[msg.sender].pendingRewards = 0;
        require(x1Token.transfer(msg.sender, rewards), "Rewards transfer failed");
        emit RewardsClaimed(msg.sender, rewards);
    }
    
    function _updateRewards(address user) internal {
        StakeInfo storage userStake = stakes[user];
        if (userStake.amount == 0) return;
        
        uint256 timeElapsed = block.timestamp - userStake.lastRewardCalculation;
        if (timeElapsed == 0) return;
        
        uint256 rewards = (userStake.amount * ANNUAL_REWARD_RATE * timeElapsed) / (365 days * 100);
        userStake.pendingRewards += rewards;
        userStake.lastRewardCalculation = block.timestamp;
    }
    
    function getStakeInfo(address user) external view returns (uint256 amount, uint256 startTime, uint256 pendingRewards) {
        StakeInfo memory userStake = stakes[user];
        uint256 timeElapsed = block.timestamp - userStake.lastRewardCalculation;
        uint256 currentRewards = (userStake.amount * ANNUAL_REWARD_RATE * timeElapsed) / (365 days * 100);
        return (userStake.amount, userStake.startTime, userStake.pendingRewards + currentRewards);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
}