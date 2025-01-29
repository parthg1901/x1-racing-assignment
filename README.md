# X1 Racing Internship Assignment

## Overview
X1Coin is implemented as an ERC-20 token with a predefined total supply and a structured token distribution mechanism. It contains several types of distribution such as Team, Community and Publi

The X1CoinStaking contract allows users to stake their X1Coin tokens, earn rewards based on an annual reward rate, and withdraw both their staked amount and accumulated rewards after the minimum staking period.

---

## Testing
Run `forge test` to execute the tests

![test](https://i.ibb.co/mCpX3cjG/Screenshot-from-2025-01-29-14-34-50.png)

## Contracts
### 1. **X1Coin (ERC-20 Token)**

**Features:**
- Total supply: **1,000,000,000 X1C** (1 billion tokens)
- Token distribution:
  - **50%** allocated for public sale
  - **30%** reserved for team and advisors (locked for **180 days**)
  - **20%** allocated for community incentives
- Team tokens are locked and released after 180 days.
- Implements **ReentrancyGuard** for security.

**Key Functions:**
- `distributeTokens()` - Distributes tokens to public sale, community, and team allocation.
- `releaseTeamTokens()` - Releases team tokens after the lock period.
- `getTeamTokensUnlockTime()` - Returns remaining lock time for team tokens.

---

### 2. **X1CoinStaking (Staking Contract)**

**Features:**
- Users can **stake X1C tokens** to earn rewards.
- A **minimum staking period of 30 days** is required before unstaking.
- **Annual reward rate of 10%**.
- Rewards are calculated based on staking duration.
- Implements **ReentrancyGuard** and **Pausable** security features.

**Key Functions:**
- `stake(uint256 amount)` - Stakes X1C tokens.
- `unstake()` - Unstakes tokens and claims rewards if the minimum period has passed.
- `claimRewards()` - Claims accumulated staking rewards.
- `getStakeInfo(address user)` - Returns staking details, including pending rewards.
- `pause()` / `unpause()` - Admin functions to pause/unpause the contract.

---

## Deployment

### **X1Coin Deployment**
1. Deploy `X1Coin` contract with constructor arguments:
   ```solidity
   new X1Coin(teamWallet, communityWallet, publicSaleWallet);
   ```
2. Call `distributeTokens()` after deployment to allocate tokens.

### **X1CoinStaking Deployment**
1. Deploy `X1CoinStaking` contract with X1Coin contract address:
   ```solidity
   new X1CoinStaking(address(X1Coin));
   ```
2. Transfer staking reward tokens to the contract using `addRewardTokens(amount)`.

### Deploy to a public network
1. Setup your `.env` file:
    Example
    ```
    PRIVATE_KEY=your_deployer_private_key
    TEAM_WALLET=0x123
    COMMUNITY_WALLET=0x123
    PUBLIC_SALE_WALLET=0x123
    ```
2. Compile using `forge build`.

3. Deploy the contracts:
    `forge script script/X1Deploy.sol:X1Deploy --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast`


---

## Security Considerations
- Uses **ReentrancyGuard** to prevent reentrancy attacks.
- Implements **Ownable** to restrict admin functions.
- **Pausable contract** allows emergency stopping of staking operations.
- Team tokens are **time-locked** for fair distribution.

---
