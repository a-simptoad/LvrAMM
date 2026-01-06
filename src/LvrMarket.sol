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

    function initializeLiquidity(uint256 collateralIn) external returns(uint256){
        require(!liquidityInitialized, "Liquidity already Initialized");
        yesToken = new YesToken(address(this), collateralIn);
        noToken = new NoToken(address(this), collateralIn);
        liquidity = SwapMath.calcInitialLiquidity(collateralIn);
        liquidityInitialized = true;
        return liquidity;
    }

    function swap(bool yesToNo, uint256 amountIn) public returns (uint256){
        // Calculates amount of tokens to give after
        uint256 amountOut = _swap(yesToNo, amountIn);

        // Mints yes and no tokens
        yesToken.mint(address(this), amountIn);
        noToken.mint(address(this), amountIn);

        // returns yes tokens through router contract 
        IERC20(yesToken).approve(msg.sender, amountOut);
        return amountOut;
        
    }

    function _swap(bool yesToNo, uint256 amountIn) internal view returns(uint256){
        uint256 newReserve = SwapMath.getSwapAmount(yesToNo, IERC20(address(yesToken)).balanceOf(address(this)), IERC20(address(noToken)).balanceOf(address(this)), liquidity, amountIn);
        return newReserve - IERC20(address(yesToken)).balanceOf(address(this));
    }

    function getUserBalance(address user) public view returns(uint256) {
        return IERC20(address(yesToken)).balanceOf(user);
    }

    function getToken(bool tokenYes) public view returns(address) {
        if(tokenYes) {
            return address(yesToken);
        }
        return address(noToken);
    }
}
