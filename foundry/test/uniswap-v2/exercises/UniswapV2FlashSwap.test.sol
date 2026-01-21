// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";
import {
    IUniswapV2Router02
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";
import {IWETH} from "../../../src/interfaces/IWETH.sol";
import {
    IUniswapV2Factory
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Factory.sol";
import {
    IUniswapV2Pair
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";

import {
    DAI,
    MKR,
    WETH,
    UNISWAP_V2_ROUTER_02,
    UNISWAP_V2_PAIR_DAI_WETH,
    UNISWAP_V2_FACTORY
} from "../../../src/Constants.sol";

import {UniswapV2Flashloan} from "./UniswapV2FlashSwap.sol";

contract UniswapV2FlashSwapTest is Test {
    IWETH private weth;
    IERC20 private dai;
    IERC20 private mkr;
    IUniswapV2Router02 private router;

    function setUp() public {
        weth = IWETH(WETH);
        dai = IERC20(DAI);
        mkr = IERC20(MKR);
        router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    }

    function test_flashSwap() public {
        UniswapV2Flashloan flashloan = new UniswapV2Flashloan();

        address user = address(0xABCD);
        vm.deal(user, 1000 * 10 ** 18);
        deal(address(dai), user, 10000 * 10 ** 18); // Give user 10,000 DAI

        address pair = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(DAI, WETH);
        console.log("Uniswap V2 DAI-WETH Pair Address:", pair);
        (uint256 reserve0, uint256 reserve1,) =
            IUniswapV2Pair(pair).getReserves();
        if (address(dai) < address(weth)) {
            console.log("DAI Reserve:", reserve0);
            console.log("WETH Reserve:", reserve1);
        } else {
            console.log("DAI Reserve:", reserve1);
            console.log("WETH Reserve:", reserve0);
        }

        vm.startPrank(user);
        // token approving for covering the flash seap fee
        weth.deposit{value: 1000 * 10 ** 18}();
        dai.approve(address(flashloan), 10000 * 10 ** 18);
        weth.approve(address(flashloan), 1000 * 10 ** 18);

        // Perform a flash swap to borrow 1000 DAI
        uint256 amountToBorrowDai = 1000 * 10 ** 18; // 1000 DAI with 18 decimals
        uint256 amountToBorrowWeth = 1000 * 10 ** 18; // 1000 WETH with 18 decimals
        (address factory, address routerAddr, address tokenA, address tokenB) = flashloan.flashSwap(
            UNISWAP_V2_FACTORY,
            UNISWAP_V2_ROUTER_02,
            DAI,
            WETH,
            amountToBorrowDai,
            amountToBorrowWeth
        );

        vm.stopPrank();

        console.log("Flash swap executed from factory:", factory);
        console.log("Using router:", routerAddr);
        console.log("Borrowed token A (DAI):", tokenA);
        console.log("Borrowed token B (WETH):", tokenB);
        console.log("Amount borrowed DAI:", amountToBorrowDai);
        console.log("Amount borrowed WETH:", amountToBorrowWeth);
    }
}
