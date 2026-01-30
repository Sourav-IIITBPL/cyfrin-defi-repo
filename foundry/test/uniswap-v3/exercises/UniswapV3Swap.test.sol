// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";
import {IWETH} from "../../../src/interfaces/IWETH.sol";
import {ISwapRouter} from "../../../src/interfaces/uniswap-v3/ISwapRouter.sol";
import {
    DAI,
    WETH,
    WBTC,
    UNISWAP_V3_SWAP_ROUTER_02
} from "../../../src/Constants.sol";

contract UniswapV3SwapTest is Test {
    IWETH private weth = IWETH(WETH);
    IERC20 private dai = IERC20(DAI);
    IERC20 private wbtc = IERC20(WBTC);
    ISwapRouter private router = ISwapRouter(UNISWAP_V3_SWAP_ROUTER_02);
    uint24 private constant POOL_FEE = 3000;

    function setUp() public {
        deal(DAI, address(this), 1000 * 1e18);
        dai.approve(address(router), type(uint256).max);
    }

    // Exercise 1
    // - Swap 1000 DAI for WETH on DAI/WETH pool with 0.3% fee
    // - Send WETH from Uniswap V3 to this contract
    function test_exactInputSingle() public {
        uint256 wethBefore = weth.balanceOf(address(this));

        // Call router.exactInputSingle
        uint256 amountOut = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(dai),
                tokenOut: address(weth),
                fee: POOL_FEE,
                recipient: address(this),
                amountIn: 1000 * 1e18,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        uint256 wethAfter = weth.balanceOf(address(this));

        console2.log("WETH amount out %e", amountOut);
        assertGt(amountOut, 0);
        assertEq(wethAfter - wethBefore, amountOut);
    }

    // Exercise 2
    // Swap 1000 DAI for WETH and then WETH to WBTC
    // - Swap DAI to WETH on pool with 0.3% fee
    // - Swap WETH to WBTC on pool with 0.3% fee
    // - Send WBTC from Uniswap V3 to this contract
    // NOTE: WBTC has 8 decimals
    function test_exactInput() public {
        // path - [dai,fee,weth,fee,wbtc]
        // Call router.exactInput
        bytes memory path = abi.encodePacked(
            address(dai), POOL_FEE, address(weth), POOL_FEE, address(wbtc)
        );
        uint256 amountOut = router.exactInput(
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                amountIn: 1000 * 1e18,
                amountOutMinimum: 1
            })
        );

        console2.log("WBTC amount out %e", amountOut);
        assertGt(amountOut, 0);
        assertEq(wbtc.balanceOf(address(this)), amountOut);
    }

    // Exercise 3
    // - Swap maximum of 1000 DAI to obtain exactly 0.1 WETH from DAI/WETH pool with 0.3% fee
    // - Send WETH from Uniswap V3 to this contract
    function test_exactOutputSingle() public {
        uint256 wethBefore = weth.balanceOf(address(this));

        // Call router.exactOutputSingle
        uint256 amountIn = router.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(dai),
                tokenOut: address(weth),
                fee: 3000,
                recipient: address(this),
                amountOut: 0.1 * 1e18,
                amountInMaximum: 1000 * 1e18,
                sqrtPriceLimitX96: 0
            })
        );

        uint256 wethAfter = weth.balanceOf(address(this));

        console2.log("DAI amount in %e", amountIn);
        assertLe(amountIn, 1000 * 1e18);
        assertEq(wethAfter - wethBefore, 0.1 * 1e18);
    }

    // Exercise 4
    // Swap maximum of 1000 DAI to obtain exactly 0.01 WBTC
    // - Swap DAI to WETH on pool with 0.3% fee
    // - Swap WETH to WBTC on pool with 0.3% fee
    // - Send WBTC from Uniswap V3 to this contract
    // NOTE: WBTC has 8 decimals
    function test_exactOutput() public {
        // path for exactoutput must be revered as compared to exactinput .
        // path - [wbtc,fee,weth,fee,dai]
        bytes memory path = abi.encodePacked(
            address(wbtc), POOL_FEE, address(weth), POOL_FEE, address(dai)
        );

        //bytes memory path = abi.encodePacked(wbtc,POOL_FEE,weth,POOL_FEE,dai);

        uint256 wbtcBefore = wbtc.balanceOf(address(this));

        // Call router.exactOutput
        uint256 amountIn = router.exactOutput(
            ISwapRouter.ExactOutputParams({
                path: path,
                recipient: address(this),
                amountOut: 1e6,
                amountInMaximum: 1000 * 1e18
            })
        );

        uint256 wbtcAfter = wbtc.balanceOf(address(this));
        console2.log("DAI amount in %e", amountIn);
        console2.log("wbtc", wbtcBefore);
        console2.log("wbtc1", wbtcAfter);
        assertLe(amountIn, 1000 * 1e18);
        assertEq(wbtcAfter, 1000_000);
    }
}
