// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract X1Coin is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public constant PUBLIC_SALE_AMOUNT = TOTAL_SUPPLY * 50 / 100;
    uint256 public constant TEAM_ADVISOR_AMOUNT = TOTAL_SUPPLY * 30 / 100;
    uint256 public constant COMMUNITY_AMOUNT = TOTAL_SUPPLY * 20 / 100;

    bool public distributionComplete;
    bool public teamTokensReleased;
    uint256 public teamTokensUnlockTime;

    address public teamWallet;
    address public communityWallet;
    address public publicSaleWallet;

    event TokensDistributed(address indexed wallet, uint256 amount);
    event TeamTokensUnlocked();

    constructor(address _teamWallet, address _communityWallet, address _publicSaleWallet)
        ERC20("X1Coin", "X1C")
        Ownable(msg.sender)
    {
        require(_teamWallet != address(0), "Invalid team wallet");
        require(_communityWallet != address(0), "Invalid community wallet");
        require(_publicSaleWallet != address(0), "Invalid public sale wallet");

        teamWallet = _teamWallet;
        communityWallet = _communityWallet;
        publicSaleWallet = _publicSaleWallet;

        teamTokensUnlockTime = block.timestamp + 180 days;
    }

    function distributeTokens() external onlyOwner nonReentrant {
        require(!distributionComplete, "Distribution already completed");

        _mint(publicSaleWallet, PUBLIC_SALE_AMOUNT);
        emit TokensDistributed(publicSaleWallet, PUBLIC_SALE_AMOUNT);

        _mint(communityWallet, COMMUNITY_AMOUNT);
        emit TokensDistributed(communityWallet, COMMUNITY_AMOUNT);

        _mint(address(this), TEAM_ADVISOR_AMOUNT);

        distributionComplete = true;
    }

    function releaseTeamTokens() external nonReentrant {
        require(distributionComplete, "Distribution not completed");
        require(!teamTokensReleased, "Team tokens already released");
        require(block.timestamp >= teamTokensUnlockTime, "Team tokens still locked");

        teamTokensReleased = true;
        _transfer(address(this), teamWallet, TEAM_ADVISOR_AMOUNT);
        emit TeamTokensUnlocked();
    }

    function getTeamTokensUnlockTime() external view returns (uint256) {
        if (block.timestamp >= teamTokensUnlockTime) {
            return 0;
        }
        return teamTokensUnlockTime - block.timestamp;
    }
}
