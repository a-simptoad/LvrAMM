// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {LvrAMM} from "src/LvrAMM.sol";

contract Router {
    error DepositFailed();
    error WithdrawFailed();

    event MarketCreated(bytes32 marketId, address resolver, address market);

    struct MarketInfo {
        address market;
        address resolver;
        uint256 liquidity;
        bool intialized;
        bytes32 data;
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

        LvrAMM market = new LvrAMM(resolver);
        /*
        Transfer USD token to market contract
        */        
        mUSD.transferFrom(msg.sender, address(market), liquidity);
        market.initializeLiquidity(liquidity);

        markets[marketId] = MarketInfo({
            market: address(market),
            resolver: resolver,
            liquidity: liquidity,
            intialized: true,
            data: bytes32(abi.encode(prediction))
        });
        
        emit MarketCreated(marketId, resolver, address(market));
    }

    function deposit(uint256 amount, address market) public {
        // User has USDc tokens
        uint256 initialBalance = mUSD.balanceOf(market);
        mUSD.transferFrom(msg.sender, address(market), amount);

        if(mUSD.balanceOf(market) >= initialBalance + amount){
            LvrAMM(market).updateBalance(msg.sender, amount);
        }else revert DepositFailed();
    }
    
    function withdraw(uint256 amount, address market) public {
        uint256 initialBalance = mUSD.balanceOf(market);

        require(LvrAMM(market).getUserBalance(msg.sender) > amount, "Insufficient Balance");
        mUSD.transferFrom(address(market), msg.sender, amount);

        if(mUSD.balanceOf(market) <= initialBalance - amount){
            LvrAMM(market).updateBalance(msg.sender, amount);
        }else revert WithdrawFailed();
    }

    function buy(address market, uint256 amount) public {
        
    }

    function sell() public {}

    function depositAndBuyToken() public {}

    function sellTokenAndWithdraw() public {}

    function resolveMarket() public {}
}

// A user has 100 USDC tokens (minted in the test contract.)
// He uses those tokens to deposit and buy yes/no tokens of a market