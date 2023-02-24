// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./CustomIERC721.sol";
import "./CustomIERC20.sol";

struct Stake {
    address stakeholder;
    address contractAddress;
    string tokenName;
    uint256 amount;
    uint256 stakedAt;
    uint256 unStakedAt;
    uint256 claimedAt;
    uint256 rewardAmount;
    bool isUnstaked;
    bool isRewardClaimed;
    bool isStaked;
}

struct NftReward {
    uint256 tokenId;
    uint256 NFTclaimedAt;
    bool isNFTClaimed;
}

contract Defi {
    using SafeMath for uint256;

    CustomIERC20 public rewardToken;
    address private _GateAddress;

    address public admin;
    uint256 internal unstakePeriod;
    uint256 internal minimumStakes;
    uint256 internal maximumStakes;
    uint256 public totalStakes;
    uint256 public lockTime;
    uint256 public rewardInterval;
    uint256 public rewardRate;

    mapping(uint256 => Stake) public stakes;
    mapping(uint256 => NftReward) public nftRewards;
    mapping(address => uint256[]) public userStakelist;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Message sender must be the contract's owner."
        );
        _;
    }

    constructor(address _NFTAddress, address _rewardToken) {
        admin = msg.sender;
        rewardToken = CustomIERC20(_rewardToken);
        _GateAddress = _NFTAddress;
    }

    function setMinimumStakevalue(uint256 _value) public onlyAdmin {
        require(_value > 0, "value must greater than 0");
        minimumStakes = _value;
    }

    function setMaximumStakevalue(uint256 _value) public onlyAdmin {
        require(_value > 0, "value must greater than 0");
        maximumStakes = _value;
    }

    function setLocktime(uint256 _locktime) public onlyAdmin {
        require(_locktime > 0, "value must greater than 0");
        lockTime = _locktime;
    }

    function setRewardInterval(uint256 _rewardInterval) public onlyAdmin {
        require(_rewardInterval > 0, "value must greater than 0");
        rewardInterval = _rewardInterval;
    }

    function setRewardRate(uint256 _value) public onlyAdmin {
        require(_value > 0, "value must greater than 0");
        rewardRate = _value;
    }

   modifier mandatory {
       require(minimumStakes > 1);
       require(lockTime > 1); 
       require(rewardInterval > 1);
       require(rewardRate > 1);
       _;
   }
   
    function stakeTokens(uint256 _amount, address _tokenAddress) public mandatory {
        
        require(_amount >= minimumStakes, "You must stake at least 100 tokens");
        require(
            _amount <= maximumStakes,
            "You are not able to stakes more than 100000 tokens"
        );
        require(
            CustomIERC20(_tokenAddress).balanceOf(msg.sender) >= _amount,
            "Not enough Balance"
        );
        require(
            CustomIERC20(_tokenAddress).allowance(msg.sender, address(this)) >=
                _amount,
            "Not sufficient allowance"
        );


        Stake memory stake = Stake(
            msg.sender,
            _tokenAddress, 
            CustomIERC20(_tokenAddress).name(), 
            _amount, 
            block.timestamp, 
            0, 
            0, 
            0, 
            false, 
            false,
            true
        );
       
        totalStakes = totalStakes + 1;
        stakes[totalStakes] = stake;
        userStakelist[msg.sender].push(totalStakes);

        CustomIERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
    }

    function _calculateReward(uint256 _stakeID) internal returns (uint256) {
        uint256 value = stakes[_stakeID]
            .amount
            .mul(rewardRate)
            .mul(stakes[_stakeID].unStakedAt.sub(stakes[_stakeID].stakedAt))
            .div(100);
        stakes[_stakeID].rewardAmount = value.div(31536000);
        return stakes[_stakeID].rewardAmount;
    }

    function unstakeTokens(uint256 _stakeID) public {
        Stake memory stake = stakes[_stakeID];
        require(!(stake.isStaked), "Your funds withdrawn already");
        require(
            stake.stakeholder == msg.sender,
            "caller must be a stakeholder"
        );
        require(stake.isUnstaked == false, "The stake has withdrwan already");
        unstakePeriod = stake.stakedAt.add(lockTime);
        require(
            block.timestamp >= unstakePeriod,
            "tokens available after the period"
        );
        stake.unStakedAt = block.timestamp;
        stake.isUnstaked = true;
        stakes[_stakeID] = stake;
        _calculateReward(_stakeID);
        CustomIERC20(stake.contractAddress).transfer(msg.sender, stake.amount);
    }

     function claimRewardTokens(uint256 _stakeID) public onlyAdmin {
        Stake memory stake = stakes[_stakeID];
        if (stake.rewardAmount > 0) {
            stake.isRewardClaimed = true;
            stake.claimedAt = block.timestamp;
            rewardToken.mint(stake.stakeholder, stake.rewardAmount);
        }
        stakes[_stakeID] = stake;
    }

    function claimNFTReward(
        uint256 _stakeID
    ) public {
        Stake memory stake = stakes[_stakeID];
        NftReward memory nftReward = nftRewards[_stakeID];
        uint256 nftIssuance = stake.stakedAt.add(rewardInterval);
        CustomIERC721 ierc721 = CustomIERC721(_GateAddress);
        require(stake.isUnstaked == false,"Your funds withdrawn already");
        require(nftRewards[_stakeID].isNFTClaimed == false,"Claimed your NFT already");
        require(
            block.timestamp >= nftIssuance,
            "Tokens are only available after correct time period has elapsed"
        );
       // take the current tokenID from the NFT contract
               ierc721.safeMint(msg.sender);
        nftReward.tokenId = ierc721.currentTokenId();
        nftReward.isNFTClaimed = true;
        nftReward.NFTclaimedAt = block.timestamp;
        nftRewards[_stakeID] = nftReward;
    }  
}
