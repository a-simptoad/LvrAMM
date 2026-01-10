// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {YesToken, NoToken} from "./Token.sol";
import {SwapMath} from "./lib/SwapMath.sol";
import {Math} from "./lib/Math.sol";

contract LvrMarket {

    YesToken public yesToken;
    NoToken public noToken;

    address immutable i_resolver;
    uint256 private liquidity;

    bool private liquidityInitialized;
    bool private isDynamic;

    uint256 private deadline;

    constructor(address _resolver, bool _type, uint256 duration){
        i_resolver = _resolver;
        isDynamic = _type;

        deadline = block.timestamp + duration;
    }

    function initializeLiquidity(uint256 collateralIn) external returns(uint256){
        require(!liquidityInitialized, "Liquidity already Initialized");
        yesToken = new YesToken(address(this), collateralIn);
        noToken = new NoToken(address(this), collateralIn);
        liquidity = Math.calcInitialLiquidity(collateralIn);
        liquidityInitialized = true;
        return liquidity;
    }

    function buy(bool yesToNo, uint256 amountIn) public returns (uint256){
        // Calculates amount of tokens to give after
        uint256 amountOut = _swap(yesToNo, int256(amountIn));

        // Mints yes and no tokens
        yesToken.mint(address(this), amountIn);
        noToken.mint(address(this), amountIn);

        // returns yes tokens through router contract 
        if(yesToNo){
            IERC20(noToken).approve(msg.sender, amountIn + amountOut);
        }else{
            IERC20(yesToken).approve(msg.sender, amountIn + amountOut);
        }
        return amountOut;
    }

    function sell(bool yesToNo, uint256 amountIn) public returns (uint256){
        uint256 amountOut = _swap(yesToNo, int256(amountIn));

        if(yesToNo){
            IERC20(noToken).approve(msg.sender, amountOut);
        }else{
            IERC20(yesToken).approve(msg.sender, amountOut);
        }
        return amountOut;
    }

    function _swap(bool yesToNo, int256 amountIn) internal view returns(uint256){
        require(block.timestamp > deadline, "Market Expired");

        uint256 liq;
        if(isDynamic){
            liq = Math.calcLiquidity(liquidity, deadline, block.timestamp);
        }else{
            liq = liquidity;
        }
        int256 currentReserveYes = int256(IERC20(address(yesToken)).balanceOf(address(this)));
        int256 currentReserveNo = int256(IERC20(address(noToken)).balanceOf(address(this)));
        uint256 amountOut = SwapMath.getSwapAmount(yesToNo, currentReserveYes, currentReserveNo, liq, amountIn);
        return amountOut;
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

    function getPriceYes() public view returns(uint256) {
        return Math.calcPrice(yesToken.balanceOf(address(this)), noToken.balanceOf(address(this)), liquidity);
    }
}
