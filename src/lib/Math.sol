// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {FixedPointMathLib} from "lib/solady/src/utils/FixedPointMathLib.sol";
import {Gaussian} from "./Gaussian.sol";

contract Math{
    using FixedPointMathLib for uint256;
    using FixedPointMathLib for int256;

    /**
     * @dev calculates the price of token
     */
    function calcPrice(uint256 x, uint256 y, uint256 l) internal pure returns(uint256){
        // price = cdf((x-y) / L)

        int256 delta = int256(y) - int256(x);
        int256 z = delta.sMulWad(int256(l));

        int256 price = Gaussian.cdf(z);
        return uint256(price);
    }
}