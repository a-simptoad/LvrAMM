// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {LvrMarket} from "src/LvrMarket.sol";

contract Router {
    event MarketCreated(bytes32 marketId, address resolver, address market);

    struct MarketInfo {
        address market;
        address resolver;
        uint256 liquidity;
        bool intialized;
    }

    mapping(bytes32 marketId => MarketInfo info) public markets;
    // mapping(address user => uint256 deposit) public balances;
    IERC20 public mUSD;
    
    constructor(address _mUSD){
        mUSD = IERC20(_mUSD);
    } 

    function create(string memory prediction, uint256 liquidity, address resolver) public {
        // A new market is deployed
        bytes32 marketId = keccak256(abi.encodePacked(prediction, resolver));
        require(!markets[marketId].intialized, "Market Already Exists");

        LvrMarket market = new LvrMarket(resolver);
        /*
        Transfer USD token to market contract
        */        
        mUSD.transferFrom(msg.sender, address(market), liquidity);
        market.initializeLiquidity(liquidity);

        markets[marketId] = MarketInfo({
            market: address(market),
            resolver: resolver,
            liquidity: liquidity,
            intialized: true
        });
        
        emit MarketCreated(marketId, resolver, address(market));
    }

    // function deposit(uint256 amount, address market) public {}
    
    // function withdraw(uint256 amount, address market) public {}

    function buyYes(address market, uint256 amount) public {
        // Takes mUSD from user
        // Mints Yes + No token
        // Sells No token to AMM
        // Sends corresponding Yes token to User

        mUSD.transferFrom(msg.sender, market, amount);
        LvrMarket(market).swap(amount, msg.sender);
    }

    function sellYes() public {}

    // function depositAndBuyToken() public {}

    // function sellTokenAndWithdraw() public {}

    function resolveMarket() public {}
}

// A user has 100 USDC tokens (minted in the test contract.)
// He uses those tokens to deposit and buy yes/no tokens of a market