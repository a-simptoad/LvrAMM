// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {LvrMarket} from "src/LvrMarket.sol";

contract Router {
    event MarketCreated(bytes32 marketId, address resolver, address market);

    struct MarketInfo {
        address market;
        uint256 liquidity;
        bool intialized;
    }

    mapping(bytes32 marketId => MarketInfo info) public markets;
    IERC20 public mUSD; // Collateral Token
    
    constructor(address _mUSD){
        mUSD = IERC20(_mUSD);
    } 

    function create(string memory prediction, uint256 collateralIn, address resolver) public {
        // A new market is deployed
        bytes32 marketId = keccak256(abi.encodePacked(prediction, resolver));
        require(!markets[marketId].intialized, "Market Already Exists");

        LvrMarket market = new LvrMarket(resolver);
        /*
        Transfer USD token to market contract
        */        
        mUSD.transferFrom(msg.sender, address(market), collateralIn);
        uint256 liquidity = market.initializeLiquidity(collateralIn);

        markets[marketId] = MarketInfo({
            market: address(market),
            liquidity: liquidity,
            intialized: true
        });
        
        emit MarketCreated(marketId, resolver, address(market));
    }

    function buyYes(address market, uint256 collateralIn) public {
        // Takes mUSD from user
        // Mints Yes + No token
        // Sells No token to AMM
        // Sends corresponding Yes token to User

        mUSD.transferFrom(msg.sender, market, collateralIn);
        uint256 amountOut = LvrMarket(market).swap(false, collateralIn);
        IERC20(LvrMarket(market).getToken(true)).transferFrom(market, msg.sender, amountOut);
    }

    function sellYes() public {}

    function resolveMarket() public {}
}