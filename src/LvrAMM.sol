// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract LvrAMM {

    mapping(address user => uint256 deposit) private balances;
    IERC20 public yesToken;
    IERC20 public noToken;

    address immutable i_resolver;

    constructor(uint256 liquidity, address _resolver){
        i_resolver = _resolver;
    }

    function initializeLiquidity(uint256 liquidity) public {
        
    }

    function updateBalance(address sender, uint256 amount) public {
        balances[sender] += amount;
    }
}
