// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {LvrMarket} from "src/LvrMarket.sol";
import {IMarketBuyCallback} from "./interfaces/IMarketBuyCallback.sol";
import {IMarketSellCallback} from "./interfaces/IMarketSellCallback.sol";
import {IMarketRedeemCallback} from "./interfaces/IMarketRedeemCallback.sol";   
import {IMarketBondCallback} from "./interfaces/IMarketBondCallback.sol";

contract Router is IMarketBuyCallback, IMarketSellCallback, IMarketRedeemCallback, IMarketBondCallback{
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

        LvrMarket market = new LvrMarket(address(this), isDynamic, duration, address(mUSD), msg.sender);
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

        LvrMarket(market).buy(true, collateralIn, msg.sender);
    }

    function buyNo(address market, uint256 collateralIn) public {
        LvrMarket(market).buy(false, collateralIn, msg.sender);
    }

    function sellYes(address market, uint256 tokenIn) public {
        // Takes yesToken from the user
        // Sells Yes token to AMM
        // Sends corresponding No token to User
        LvrMarket(market).sell(true, tokenIn, msg.sender);
    }

    function sellNo(address market, uint256 tokenIn) public {
        LvrMarket(market).sell(false, tokenIn, msg.sender);
    }

    function proposerOutcome(address market, uint256 _outcome) public {
        LvrMarket(market).proposeOutcome(_outcome, msg.sender);
    }

    function dispute(address market) public {
        LvrMarket(market).dispute();
    }

    function settleMarket(address market) public {
        LvrMarket(market).settleMarket();
    }

    function redeem(address market, uint256 amountYes, uint256 amountNo) public {
        LvrMarket(market).redeemCollateralWithToken(amountYes, amountNo, msg.sender);
    }

    // Callbacks

    function marketBuyCallback(uint256 collateralIn, bytes calldata data) external override {
        (address collateral, address buyer) = abi.decode(data, (address, address));

        // msg.sender is the Market Contract which calls the callback
        IERC20(collateral).transferFrom(buyer, msg.sender, collateralIn);
    }

    function marketSellCallback(uint256 tokenIn, bytes calldata data) external override {
        (address tokenToSell, address seller) = abi.decode(data, (address, address));

        IERC20(tokenToSell).transferFrom(seller, msg.sender, tokenIn);
    }

    function marketRedeemCallback(uint256 amountYes, uint256 amountNo, bytes calldata data) external override {
        (address yesToken, address noToken, address redeemer) = abi.decode(data, (address, address, address));

        IERC20(yesToken).transferFrom(redeemer, msg.sender, amountYes);
        IERC20(noToken).transferFrom(redeemer, msg.sender, amountNo);
    }

    function marketBondCallback(uint256 bond, bytes calldata data) external override {
        (address collateral, address proposer) = abi.decode(data, (address, address));

        IERC20(collateral).transferFrom(proposer, msg.sender, bond);
    }
}