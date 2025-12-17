// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

contract YesToken is ERC20{
    constructor() ERC20("YesToken", "YES") {
        
    }
}