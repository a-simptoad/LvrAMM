// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Math} from "./Math.sol";
import {Gaussian} from "./Gaussian.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

library SwapMath {
    int256 constant APPROX = 1e15;
    int256 constant MAX_ITERS = 10;

    function ammFunc(int256 x, int256 y, int256 l) internal pure returns(int256) {
        int256 z = FixedPointMathLib.sDivWad((y-x), l);
        return FixedPointMathLib.sMulWad((y-x) ,Gaussian.cdf(z)) 
        +  FixedPointMathLib.sMulWad(l, Gaussian.pdf(z)) 
        - y;
        // Provides the value of the invariant function when input values are x, y and initial liquidity is l
    }

    function funcDerivative(int256 x, int256 y, int256 l) internal pure returns(int256) {
        int256 z = FixedPointMathLib.sDivWad((y-x), l);
        return -Gaussian.cdf(z);
    }

    function getNewReserve(int256 x, int256 y, int256 l) internal pure returns (int256) { // x is the token reserve to calculate
        int256 t = x;

        for(int256 i = 0; i < MAX_ITERS; i++){
            int256 f = ammFunc(t, y, l);
            if(abs(f) < APPROX){
                return abs(t);
            }
            t = t - FixedPointMathLib.sDivWad(
                        f , funcDerivative(t, y, l)
                    );
        }
        return abs(t); // NewReserve
    }

    function abs(int256 f) internal pure returns(int256) {
        return (f > 0 ? f : -f);
    }

// inputs ->
// Current Reserve of Yes token
// Current Reserve of No token 
// Amount of token No to swap for token Yes || Amount of token Yes to swap for token No
// Initial liquidity of the market
// Invariant function
// f(t) = (a + t) * Gaussian.cdf((a + t) / liquidity) + liquidity * Gaussian.pdf((a + t) / liquidity) - y

    function getSwapAmount(bool yesToNo, int256 currentReserveYes, int256 currentReserveNo, uint256 initialLiquidity, int256 amountIn) external pure returns(uint256){
        if(yesToNo){
            return uint256(abs(currentReserveNo - getNewReserve(currentReserveNo, currentReserveYes + amountIn, int256(initialLiquidity))));
        }
        return uint256(abs(currentReserveYes - getNewReserve(currentReserveYes, currentReserveNo + amountIn, int256(initialLiquidity))));
    }

}