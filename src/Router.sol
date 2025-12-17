// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {LvrAMM} from "src/LvrAMM.sol";

contract Router {
    struct Market {
        address resolver;
        uint256 liquidity;
        address yesToken;
        address noToken;
        bytes data;
    }

    LvrAMM public amm;

    mapping(bytes marketId => Market market) public markets;
    mapping(address user => uint256 deposit) public deposits;

    function create(string memory prediction, uint256 liquidity, address resolver) public {
        // A new market is deployed
    }

    function buy() public {

    }

    function sell() public {

    }

    function resolveMarket() public {

    }
}

// A user has 100 USDC tokens (minted in the test contract.)
// He uses those tokens 