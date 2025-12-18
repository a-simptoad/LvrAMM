// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {YesToken, NoToken} from "./Token.sol";

contract LvrAMM {

    mapping(address user => uint256 deposit) private balances;
    IERC20 public yesToken;
    IERC20 public noToken;

    address immutable i_resolver;

    constructor(address _resolver){
        i_resolver = _resolver;
    }

    function initializeLiquidity(uint256 liquidity) public {
        yesToken = new YesToken(address(this), liquidity);
        noToken = new NoToken(address(this), liquidity);
    }

    function updateBalance(address sender, uint256 amount) public {
        balances[sender] += amount;
    }

    function getUserBalance(address user) public view returns(uint256) {
        return balances[user];
    }
}
