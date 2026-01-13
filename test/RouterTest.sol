// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Router} from "src/Router.sol";
import {LvrMarket} from "src/LvrMarket.sol";
import {MockUSD} from "src/MockUSD.sol";
import {Math} from "src/lib/Math.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract RouterTest is Test{
    uint256 constant INITIAL_USER_DEPOSIT = 100 ether;
    uint256 constant INITIAL_MARKET_COLLATERAL = 1000 ether;
    uint256 constant COLLATERAL_DEPOSIT = 10 ether;

    Router router;
    MockUSD mUSD;

    address public user = makeAddr("user");
    address public marketCreator = makeAddr("creator");

    address public market;

    function setUp() public {
        mUSD = new MockUSD();
        router = new Router(address(mUSD));

        mUSD.mint(user, INITIAL_USER_DEPOSIT);
        mUSD.mint(marketCreator, INITIAL_MARKET_COLLATERAL);
    }

    modifier createMarket {
        string memory prediction = "Will Eth go above 4000 usd";

        vm.startPrank(marketCreator);
        mUSD.approve(address(router), INITIAL_MARKET_COLLATERAL);
        router.create(prediction, INITIAL_MARKET_COLLATERAL, address(0));
        (market,,) = router.markets(keccak256(abi.encodePacked(prediction, address(0))));
        vm.stopPrank();
        _;
    }

    function test_CreateMarket() public createMarket {
        string memory prediction = "Will Eth go above 4000 usd";

        vm.startPrank(marketCreator);
        bytes32 expectedMarketId = keccak256(abi.encodePacked(prediction, address(0)));
        uint256 expectedLiquidity = Math.calcInitialLiquidity(INITIAL_MARKET_COLLATERAL);
        (address market, uint256 liquidity, bool initialized) = router.markets(expectedMarketId);

        assertTrue(initialized, "Market not initialized");
        assertEq(liquidity, expectedLiquidity, "Liquidity is Invalid");

        assertEq(mUSD.balanceOf(market), INITIAL_MARKET_COLLATERAL, "Total collateral not received");
        assertEq(mUSD.balanceOf(marketCreator), 0 ether, "Collateral still with creator");

        vm.stopPrank();
    }

    function test_buyYes() public createMarket {
        vm.startPrank(user);
        mUSD.approve(address(router), COLLATERAL_DEPOSIT);
        router.buyYes(market, COLLATERAL_DEPOSIT);
        vm.stopPrank();

        assertEq(mUSD.balanceOf(user), INITIAL_USER_DEPOSIT - COLLATERAL_DEPOSIT, "Collateral still with User");
        assertEq(mUSD.balanceOf(market), INITIAL_MARKET_COLLATERAL + COLLATERAL_DEPOSIT, "Collateral not received");

        address yesToken = LvrMarket(market).getToken(true);
        console.log(IERC20(yesToken).balanceOf(user));
    }
}

// TO-DO
// 1. Add zero address error to the functions.
// 2. Add a check for collateral entered for buy and sell functions in LvrMarket (specially before minting yes and no tokens)
// 3. Add event in market
