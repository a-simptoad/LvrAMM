// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {YesToken, NoToken} from "./Token.sol";
import {SwapMath} from "./lib/SwapMath.sol";

contract LvrMarket {

    YesToken public yesToken;
    NoToken public noToken;

    address immutable i_resolver;
    uint256 private liquidity;

    bool private liquidityInitialized;

    constructor(address _resolver){
        i_resolver = _resolver;
    }

    function initializeLiquidity(uint256 _liquidity) external {
        require(!liquidityInitialized, "Liquidity already Initialized");
        liquidity = _liquidity;
        yesToken = new YesToken(address(this), liquidity);
        noToken = new NoToken(address(this), liquidity);
        liquidityInitialized = true;
    }

    function mintToken(uint256 amount) internal {
        yesToken.mint(address(this), amount);
        noToken.mint(address(this), amount);
    }

    function swap(uint256 amountIn, address to) public {
        mintToken(amountIn);
        IERC20(address(yesToken)).transfer(to, amountIn);
        // Now the Market has (liquidity) yes tokens and (liquidity + amount) no tokens
        // When i do _swap then the amm calculates 
        _swap(to);
    }

    function _swap(address to) internal {
        uint256 amountOut = SwapMath.getSwapAmount(IERC20(address(yesToken)).balanceOf(address(this)), IERC20(address(noToken)).balanceOf(address(this)), liquidity);
        IERC20(address(yesToken)).transfer(to, amountOut);

    }

    function getUserBalance(address user) public view returns(uint256) {
        return IERC20(address(yesToken)).balanceOf(user);
    }
}
