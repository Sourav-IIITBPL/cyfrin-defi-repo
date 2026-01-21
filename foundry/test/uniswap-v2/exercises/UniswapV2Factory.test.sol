// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";
import {IWETH} from "../../../src/interfaces/IWETH.sol";
import {
    IUniswapV2Factory
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Factory.sol";
import {
    IUniswapV2Pair
} from "../../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {
    DAI,
    WETH,
    UNISWAP_V2_PAIR_DAI_WETH,
    UNISWAP_V2_FACTORY
} from "../../../src/Constants.sol";
import {ERC20} from "../../../src/ERC20.sol";

contract UniswapV2FactoryTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IUniswapV2Factory private constant factory =
        IUniswapV2Factory(UNISWAP_V2_FACTORY);

    function test_createPair() public {
        ERC20 tokenA = new ERC20("TokenA", "TKA", 18);
        address pair = IUniswapV2Factory(factory)
            .createPair(address(tokenA), address(weth));
        console.log("New pair address:", pair);
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        console.log("Token0 address:", token0);
        console.log("Token1 address:", token1);
        if (address(tokenA) < address(weth)) {
            assertEq(token0, address(tokenA), "Token0 should be TokenA");
            assertEq(token1, address(weth), "Token1 should be WETH");
        } else {
            assertEq(token0, address(weth), "Token0 should be WETH");
            assertEq(token1, address(tokenA), "Token1 should be TokenA");
        }

        // New pair address: 0x35318373409608AFC0f2cdab5189B3cB28615008
        // Token0 address: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
        // Token1 address: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        //
    }
}
