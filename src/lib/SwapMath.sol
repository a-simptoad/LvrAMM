// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Math} from "./Math.sol";
import {Gaussian} from "./Gaussian.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

library SwapMath {
    int256 constant APPROX = 1e15;

    function getSwapAmount(uint256 currentYesReserves, uint256 currentNoReserves, uint256 liquidity) external pure returns(uint256) {
        // Invariant function
        // f(t) = (a + t) * Gaussian.cdf((a + t) / liquidity) + liquidity * Gaussian.pdf((a + t) / liquidity) - y
        // int256 delta = int256(currentNoReserves) - int256(currentYesReserves);
        // int256 z = FixedPointMathLib.sDivWad(delta, liquidity);
        int256 x = int256(currentYesReserves);
        int256 y = int256(currentNoReserves);
        int256 l = int256(liquidity);

        return uint256(getAmountYes(x, y, l));
    }

    function getAmountYes(int256 x, int256 y, int256 l) internal pure returns(int256) {
        // x2 = x1 - f(x1)/ f'(x1)
        int256 t = 0;
        for(uint256 i = 0; i < 10; i++) {
            t = t - FixedPointMathLib.sDivWad(invariantFunction(t, x, y, l), deriInvariantFunc(t, x, y, l));
            int256 f = invariantFunction(t, x, y, l);
            if(f < APPROX || f > -APPROX){
                return t;
            }else continue;
        }
        // ??
        return t;
    }

    function invariantFunction(int256 t, int256 x, int256 y, int256 l) internal pure returns(int256) {
        // Invariant function
        // f(t) = (a + t) * Gaussian.cdf((a + t) / liquidity) + liquidity * Gaussian.pdf((a + t) / liquidity) - y
        int256 z = FixedPointMathLib.sDivWad((y-x + t), l);
        return FixedPointMathLib.sMulWad((y-x + t) ,Gaussian.cdf(z)) +  FixedPointMathLib.sMulWad(l, Gaussian.pdf(z)) - y;
    }

    function deriInvariantFunc(int256 t, int256 x, int256 y, int256 l) internal pure returns(int256){
        int256 z = FixedPointMathLib.sDivWad((y-x + t), l);
        return Gaussian.cdf(z);
    }
}

/// Check whether the conversion of uint -> int does not give error i.e a number of size greater than 128 bytes will get overflowed on conversion