// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";
import {IWETH} from "../../../src/interfaces/IWETH.sol";
import {
    IUniswapV2Router02
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";
import {
    IUniswapV2Pair
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {
    IUniswapV2Factory
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Factory.sol";
import {
    DAI,
    WETH,
    MKR,
    UNISWAP_V2_PAIR_DAI_MKR,
    UNISWAP_V2_ROUTER_02,
    UNISWAP_V2_FACTORY
} from "../../../src/Constants.sol";

import {ERC20} from "../../../src/ERC20.sol";

contract UniswapV2SwapTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);

    IUniswapV2Router02 private constant router =
        IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Pair private constant pair =
        IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_MKR);

    address private constant user = address(100);

    function setUp() public {
        deal(user, 100 * 1e18);
        vm.startPrank(user);
        weth.deposit{value: 100 * 1e18}();
        weth.approve(address(router), type(uint256).max);
        vm.stopPrank();

        // Add MKR liquidity to DAI/MKR pool
        deal(DAI, address(pair), 1e6 * 1e18);
        deal(MKR, address(pair), 1e5 * 1e18);
        pair.sync();
    }

    // Swap all input tokens for as many output tokens as possible
    function test_swapExactTokensForTokens() public {
        address user = address(1);
        vm.deal(user, 10e18); // give user 10 WETH
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(dai);
        path[2] = address(mkr);
        uint256 amountIn = 1e18; // 1 WETH
        uint256 amountOutMin = 1e15; // 0.001 MKR
        vm.startPrank(user);
        weth.deposit{value: amountIn}();
        weth.approve(address(router), amountIn);
        uint256[] memory amounts = router.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            path: path,
            to: user,
            deadline: block.timestamp + 1000
        });
        vm.stopPrank();
        console.log("Amount of weth spent", amounts[0]);
        console.log("Amount of dai bought", amounts[1]);
        console.log("Amount of mkr bought", amounts[2]);

        assertGt(amounts[2], amountOutMin, "Did not receive enough MKR");
        //       Amount of weth spent 1000000000000000000
        // Amount of dai bought 3089528293800335233768
        // Amount of mkr bought 46555118693399564
    }

    // Receive an exact amount of output tokens for as few input tokens
    // as possible
    function test_swapTokensForExactTokens() public {
        address user = address(1);
        vm.deal(user, 10e18); // give user 10 WETH
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(dai);
        path[2] = address(mkr);
        uint256 amountOut = 1e16; // 0.01 MKR
        uint256 amountInMax = 1e18; // 1 WETH

        vm.startPrank(user);
        weth.deposit{value: amountInMax}();
        weth.approve(address(router), amountInMax);
        uint256[] memory amounts = router.swapTokensForExactTokens({
            amountOut: amountOut,
            amountInMax: amountInMax,
            path: path,
            to: user,
            deadline: block.timestamp + 1000
        });
        vm.stopPrank();
        console.log("Amount of weth spent", amounts[0]);
        console.log("Amount of dai bought", amounts[1]);
        console.log("Amount of mkr bought", amounts[2]);
        assertEq(amounts[2], amountOut, "Did not receive exact MKR");
        assertGt(amountInMax, amounts[0], " spending is greater than max");
        //       Amount of weth spent 5823788219822373
        // Amount of dai bought 18001497796751046760
        // Amount of mkr bought 10000000000000000
    }

    function test_getAmountIn() public view {
        address[] memory path = new address[](3);
        path[0] = address(weth);
        path[1] = address(dai);
        path[2] = address(mkr);
        uint256 amountOut = 1e16; // 1e18 will cause an error: `[Revert] ds-math-sub-underflow`
        uint256[] memory amountsIn = router.getAmountsIn(amountOut, path);
        console.log("Amount of weth needed", amountsIn[0]);
        console.log("Amount of dai needed", amountsIn[1]);
        console.log("Amount of mkr out", amountsIn[2]);

        //       Amount of weth needed 6054548944057446
        // Amount of dai needed 18714783758475040778
        // Amount of mkr out 0.0010000000000000000
    }
}
