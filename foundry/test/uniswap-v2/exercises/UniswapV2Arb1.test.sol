// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";
import {IWETH} from "../../../src/interfaces/IWETH.sol";
import {
    IUniswapV2Router02
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";
import {
    IUniswapV2Factory
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Factory.sol";
import {
    DAI,
    WETH,
    MKR,
    HOPR,
    UNISWAP_V2_FACTORY,
    UNISWAP_V2_ROUTER_02,
    SUSHISWAP_V2_ROUTER_02,
    UNISWAP_V2_PAIR_DAI_WETH,
    UNISWAP_V2_PAIR_DAI_MKR
} from "../../../src/Constants.sol";

import {UniswapV2Arbitrage1} from "./UniswapV2Arb1.sol";

// Test arbitrage between Uniswap and Sushiswap
// Buy WETH on Uniswap, sell on Sushiswap.
// For flashSwap, borrow DAI from DAI/hopr pair

// currently on dai/weth pool in uniswap spot price is 3250 dai/weth  and on sushiswap its 3312 dai/weth .
contract Arbitrage1 is Test {
    IWETH private weth;
    IERC20 private dai;
    IERC20 private mkr;
    IERC20 private hopr;
    IUniswapV2Router02 private uni_router;
    IUniswapV2Router02 private sushi_router;

    UniswapV2Arbitrage1 Arbitrage1;

    function setUp() public {
        weth = IWETH(WETH);
        dai = IERC20(DAI);
        mkr = IERC20(MKR);
        hopr = IERC20(HOPR);
        uni_router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
        sushi_router = IUniswapV2Router02(SUSHISWAP_V2_ROUTER_02);

        Arbitrage1 = new UniswapV2Arbitrage1();
    }

    // user will borrow around 1 weth from 3250 dai and then sell 1 weth into sushiswap.
    function testSwap() public {
        address user = makeAddr("user");
        vm.deal(user, 100 ether);
        deal(address(dai), user, 10_000 * 10 ** 18);
        vm.prank(user);
        weth.deposit{value: 100 ether}();
        // preview
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(weth);
        uint256 amountOut = 1e18;
        uint256[] memory amountsIn = uni_router.getAmountsIn(amountOut, path);
        console.log("preview: Amount of dai needed", amountsIn[0]);
        console.log("preview: Amount of weth out", amountsIn[1]);

        uint256 daiAmount = amountsIn[0];
        uint256 daibalance0 = dai.balanceOf(user);
        vm.startPrank(user);
        dai.approve(address(Arbitrage1), daiAmount);
        Arbitrage1.swap(
            UniswapV2Arbitrage1.SwapParams({
                router0: address(uni_router),
                router1: address(sushi_router),
                token0: address(dai),
                token1: address(weth),
                amountIn: daiAmount,
                amountOutMin: 1,
                minProfit: 1,
                isToken0: true
            })
        );
        vm.stopPrank();

        uint256 daibalance1 = dai.balanceOf(user);

        assertGt(daibalance1, daibalance0, "no profit");
        assertEq(
            dai.balanceOf(address(Arbitrage1)),
            0,
            "DAI balance of Arbitrage1 != 0"
        );

        console.log(
            "balance of dai tokens of user accountbefore swap", daibalance0
        );
        console.log(
            "balance of dai tokens of user account after swap", daibalance1
        );
        console.log("Swap profit of dai tokens", daibalance1 - daibalance0);
    }

    function testFlashSwap() public {
        address user = makeAddr("user");
        uint256 daibalance0 = dai.balanceOf(user);
        vm.startPrank(user);
        uint256 daiAmount = 10_000 * 10 ** 18;
        address pair = IUniswapV2Factory(UNISWAP_V2_FACTORY)
            .getPair(address(dai), address(hopr));
        Arbitrage1.flashSwap(
            pair,
            address(dai) < address(hopr) ? true : false,
            UniswapV2Arbitrage1.SwapParams({
                router0: address(sushi_router),
                router1: address(uni_router),
                token0: address(dai),
                token1: address(weth),
                amountIn: daiAmount,
                amountOutMin: 1,
                minProfit: 1,
                isToken0: true
            })
        );
        vm.stopPrank();

        uint256 daibalance1 = dai.balanceOf(user);

        assertGt(daibalance1, daibalance0, "no profit");
        assertEq(
            dai.balanceOf(address(Arbitrage1)),
            0,
            "DAI balance of Arbitrage1 != 0"
        );
        console.log("dai/weth uniswap pair", pair);
        console.log(
            "balance of dai tokens of user accountbefore swap", daibalance0
        );
        console.log(
            "balance of dai tokens of user account after swap", daibalance1
        );
        console.log("Swap profit of dai tokens", daibalance1 - daibalance0);
    }
}

