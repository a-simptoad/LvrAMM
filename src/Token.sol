// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

contract YesToken is ERC20{
    constructor(address market, uint256 liquidity) ERC20("YesToken", "YES") {
        mint(market, liquidity);
    }

    function mint(address market, uint256 amount) public {
        _mint(market, amount);
    }

    function burn(address market, uint256 amount) public {
        _burn(market, amount);
    }
}

contract NoToken is ERC20{
    constructor(address market, uint256 liquidity) ERC20("NoToken", "NO") {
        mint(market, liquidity);
    }

    function mint(address market, uint256 amount) public {
        _mint(market, amount);
    }

    function burn(address market, uint256 amount) public {
        _burn(market, amount);
    }
}