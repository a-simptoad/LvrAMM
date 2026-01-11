// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {LvrMarket} from "src/LvrMarket.sol";

contract Router {
    event MarketCreated(bytes32 marketId, address market);

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

    function create(string memory prediction, bool isDynamic, uint256 duration, uint256 collateralIn) public {
        // A new market is deployed
        bytes32 marketId = keccak256(abi.encodePacked(prediction));
        require(!markets[marketId].intialized, "Market Already Exists");

        LvrMarket market = new LvrMarket(address(this), isDynamic, duration);
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
        
        emit MarketCreated(marketId, address(market));
    }

    function buyYes(address market, uint256 collateralIn) public {
        // Takes mUSD from user
        // Mints Yes + No token
        // Sells No token to AMM
        // Sends corresponding Yes token to User

        mUSD.transferFrom(msg.sender, market, collateralIn);
        uint256 amountOut = LvrMarket(market).buy(false, collateralIn);

        address yesToken = LvrMarket(market).getToken(true);
        IERC20(yesToken).transferFrom(market, msg.sender, collateralIn + amountOut);
    }

    function buyNo(address market, uint256 collateralIn) public {
        mUSD.transferFrom(msg.sender, market, collateralIn);
        uint256 amountOut = LvrMarket(market).buy(true, collateralIn);

        address noToken = LvrMarket(market).getToken(false);
        IERC20(noToken).transferFrom(market, msg.sender, amountOut);
    }

    function sellYes(address market, uint256 tokenIn) public {
        // The user wants to sell 10 yesToken to the market
        // He will get corresponding amount of noToken from the market 
        // Takes yesToken from the user
        // Sells Yes token to AMM
        // Sends corresponding No token to User
        uint256 amountOut = LvrMarket(market).sell(true, tokenIn);

        address yesToken = LvrMarket(market).getToken(true);
        address noToken = LvrMarket(market).getToken(false);

        IERC20(yesToken).transferFrom(msg.sender, market, tokenIn);
        IERC20(noToken).transferFrom(market, msg.sender, amountOut);
    }

    function sellNo(address market, uint256 tokenIn) public {
        uint256 amountOut = LvrMarket(market).sell(false, tokenIn);

        address yesToken = LvrMarket(market).getToken(true);
        address noToken = LvrMarket(market).getToken(false);

        IERC20(noToken).transferFrom(msg.sender, market, tokenIn);
        IERC20(yesToken).transferFrom(market, msg.sender, amountOut);
    }

    function resolveMarket() public {}
}