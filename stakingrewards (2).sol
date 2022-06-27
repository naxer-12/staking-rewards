//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract StakingRewards {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate = 100;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    // MAPPINGS
    mapping(address=>uint) public userRewardPerTokenPaid;
    mapping(address=>uint) public rewards;
    mapping(address=>uint) private _balances;

    uint private _totalSupply;

    // CONSTRUCTOR
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    // MODIFIER
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken(); //recalculate rewards
        lastUpdateTime = block.timestamp; //save current timestamp to use in next reward calculation
        rewards[account] = earned(account); //update accumulated rewards
        userRewardPerTokenPaid[account] = rewardPerTokenStored; //update last paid rewards for the given user
        _;
    }

    // Functions

    /**REWARDING PER TOKEN **/
    //used 'view' as function modifier because of not updating state
    function rewardPerToken() public view returns(uint) {
        //if there is no supply rewards token won't change
        if (_totalSupply == 0) { 
            return rewardPerTokenStored;
        }

        //calculate additional rewards and increment in stored rewardsToken

        /**Formula**/

        //REWARDPERTOKENSTORED + (CURRENT TIMESTAMP-LAST RECORDED TIMESTAMP) * RATE OF REWARD * 10^18 ) / TOTAL SUPPLY OF TOKENS
        
        // https://eth-converter.com/ for using a converted between wei and e
        return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    
    /**SUMMATION OF PREVIOUS REWARDS AND EARNED **/
    function earned(address account) public view returns(uint) {
        
        
        
        /**Formula**/

        //BALANCE OF ACCOUNT * (CURRENT REWARDS - ALREADY REWARDED TOKEN)/ 10^18 + CURRENT REWARDS IN THIS ACCOUNT
        return ((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

 
    /** STAKE THE REWARDS AND UPDATE REWARD MODIFIER TO UPDATE THE REWARDS AND TIMESTAMP**/
    function stake(uint _amount) external updateReward(msg.sender) {
        

        //increase the total supply and balance of the user
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        
        //transfering amount from user to contract 
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    /** WITHDRAWING FUND FROM CONTRACT TO USER BALANCE**/
    function withdraw(uint _amount) external updateReward(msg.sender) {
        // decreasing the amount from total supply and balance of the user
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;   
        
        //transfering amount to user from contract
        stakingToken.transfer(msg.sender, _amount);
    }

    /** COLLECT REWARDS **/
    function getReward() external updateReward(msg.sender) {
        // collect the rewards from the user
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        // transfering awards from the smart contract to the user
        rewardsToken.transfer(msg.sender, reward);
    }
}

//ERC INTERFACE BASED ON EIP-20 STANDARD
interface IERC20 {
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns(uint);
    function approve(address spender, uint amount) external returns(bool);
    function transferFrom(address spender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}