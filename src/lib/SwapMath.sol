// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Math} from "./Math.sol";
import {Gaussian} from "./Gaussian.sol";
import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";

library SwapMath {
    int256 constant APPROX = 1e15;
    int256 constant MAX_ITERS = 10;

    function getSwapAmount(uint256 currentYesReserves, uint256 currentNoReserves, uint256 liquidity) external pure returns(uint256) {
        // Invariant function
        // f(t) = (a + t) * Gaussian.cdf((a + t) / liquidity) + liquidity * Gaussian.pdf((a + t) / liquidity) - y
        // int256 delta = int256(currentNoReserves) - int256(currentYesReserves);
        // int256 z = FixedPointMathLib.sDivWad(delta, liquidity);
        int256 x = int256(currentYesReserves);
        int256 y = int256(currentNoReserves);
        int256 l = int256(liquidity);

        return uint256(getSwapAmountYes(x, y, l));
    }

    function ammFunc(int256 x, int256 y, int256 l) internal pure returns(int256) {
        int256 z = FixedPointMathLib.sDivWad((y-x), l);
        return FixedPointMathLib.sMulWad((y-x) ,Gaussian.cdf(z)) +  FixedPointMathLib.sMulWad(l, Gaussian.pdf(z)) - y;
        // Provides the value of the invariant function when input values are x, y and initial liquidity is l
    }

    function funcDerivative(int256 x, int256 y, int256 l) internal pure returns(int256) {
        int256 z = FixedPointMathLib.sDivWad((y-x), l);
        return -Gaussian.cdf(z);
    }

    function getSwapAmountYes(int256 x, int256 y, int256 l) internal pure returns (int256) {
        int256 t = x;

        for(int256 i = 0; i < MAX_ITERS; i++){
            int256 f = ammFunc(t, y, l);
            if(abs(f) < APPROX){
                return abs(t - x);
            }
            t = t - FixedPointMathLib.sDivWad(f , funcDerivative(t, y, l));
        }
        return abs(t - x);
    }

    function abs(int256 f) internal pure returns(int256) {
        return (f > 0 ? f : -f);
    }

    function calcInitialLiquidity(uint256 amount) public pure returns(uint256) {
        // amount/ pdf(0) = L
        return FixedPointMathLib.divWad(amount, uint256(Gaussian.pdf(0)));
    }
}