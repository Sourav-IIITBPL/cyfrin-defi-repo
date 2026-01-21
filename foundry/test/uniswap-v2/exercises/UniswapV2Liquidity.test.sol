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
    UNISWAP_V2_ROUTER_02,
    UNISWAP_V2_PAIR_DAI_WETH,
    UNISWAP_V2_FACTORY
} from "../../../src/Constants.sol";

contract UniswapV2LiquidityTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);

    IUniswapV2Router02 private constant router =
        IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Pair private constant pair =
        IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);

    address private constant user = address(100);

    function setUp() public {
        // Fund WETH to user
        deal(user, 100 * 1e18);
        vm.startPrank(user);
        weth.deposit{value: 100 * 1e18}();
        weth.approve(address(router), type(uint256).max);
        vm.stopPrank();

        // Fund DAI to user
        deal(DAI, user, 1000000 * 1e18);
        vm.startPrank(user);
        dai.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function test_addLiquidity() public {
        vm.deal(user, 10e18); // give user 10 WETH
        deal(address(dai), user, 20000e18); // give user 20000 DAI
        vm.startPrank(user);
        weth.deposit{value: 5e18}(); // deposit 5 WETH
        weth.approve(address(router), 5e18);
        dai.approve(address(router), 10000e18); // approve 10000 DAI
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity({
            tokenA: address(weth),
            tokenB: address(dai),
            amountADesired: 5e17,
            amountBDesired: 10000e18,
            amountAMin: 1,
            amountBMin: 1,
            to: user,
            deadline: block.timestamp + 1000
        });
        vm.stopPrank();

        address pair = IUniswapV2Factory(UNISWAP_V2_FACTORY)
            .getPair(address(weth), address(dai));

        console.log("Amount of WETH added:", amountA);
        console.log("Amount of DAI added:", amountB);
        console.log("Liquidity tokens received:", liquidity);
        assertEq(
            liquidity,
            IUniswapV2Pair(pair).balanceOf(user),
            "Liquidity tokens not received correctly"
        );

        //       Amount of WETH added: 500000000000000000  -> 5e17
        // Amount of DAI added: 1574.251519945248793173     -> 1574.251519945248793173  dai
        // Liquidity tokens received: 12.985837463326597943

        (uint256 reserve0, uint256 reserve1,) =
            IUniswapV2Pair(pair).getReserves();
        if (address(weth) < address(dai)) {
            console.log("Reserve WETH:", reserve0);
            console.log("Reserve DAI:", reserve1);
        } else {
            console.log("Reserve WETH:", reserve1);
            console.log("Reserve DAI:", reserve0);
        }

        //      Reserve WETH: 2027.063613136462470627
        // Reserve DAI: 6372752.239419121772456169
        //  ratio = 6372752.239419121772456169 / 2027.063613136462470627 = ~3145.67dai/weth
    }

    // test to distort the ratio during adding liquidity.

    function test_addLiquidityWithDistortion() public {
        vm.deal(user, 1000e18); // give user 1000 WETH
        deal(address(dai), user, 20000e18); // give user 20000 DAI
        vm.startPrank(user);
        weth.deposit{value: 5e18}(); // deposit 5 WETH
        weth.approve(address(router), 5e18);
        dai.approve(address(router), 10000e18); // approve 10000 DAI
        vm.stopPrank();

        // get reserves before adding liquidity
        address pair = IUniswapV2Factory(UNISWAP_V2_FACTORY)
            .getPair(address(weth), address(dai));
        (uint256 reserve0Before, uint256 reserve1Before,) =
            IUniswapV2Pair(pair).getReserves();

        uint256 reserveA;
        uint256 reserveB;

        if (address(weth) < address(dai)) {
            reserveA = reserve0Before;
            reserveB = reserve1Before;
        } else {
            reserveA = reserve1Before;
            reserveB = reserve0Before;
        }

        console.log(" total weth before adding anything", reserveA);
        console.log(" total dai before adding anything", reserveB);
        console.log("---- ratio before distortion ----", reserveB / reserveA);

        // add liquidity without distortion
        {
            vm.startPrank(user);
            (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity({
                tokenA: address(weth),
                tokenB: address(dai),
                amountADesired: 5e17,
                amountBDesired: 10000e18,
                amountAMin: 1,
                amountBMin: 1,
                to: user,
                deadline: block.timestamp + 1000
            });
            vm.stopPrank();

            console.log("Amount of WETH added:", amountA);
            console.log("Amount of DAI added:", amountB);
            console.log("Liquidity tokens received:", liquidity);
        }

        {
            (uint256 reserve0After, uint256 reserve1After,) =
                IUniswapV2Pair(pair).getReserves();
            uint256 reserveAAfter;
            uint256 reserveBAfter;

            if (address(weth) < address(dai)) {
                reserveAAfter = reserve0After;
                reserveBAfter = reserve1After;
            } else {
                reserveAAfter = reserve1After;
                reserveBAfter = reserve0After;
            }

            console.log(" total weth after adding liquidity", reserveAAfter);
            console.log(" total dai after adding liquidity", reserveBAfter);
            console.log(
                "---- ratio  without distortion and adding liquidity ----",
                reserveBAfter / reserveAAfter
            );
        }

        //  total weth before adding anything 2028.937812072234334060
        //    total dai before adding anything 6363747.316154778515916521
        //   ---- ratio before distortion ---- 3136
        //   Amount of WETH added: 0.500000000000000000
        //   Amount of DAI added: 1568.246024666283882496
        //   Liquidity tokens received: 12.961013437057530733
        //    total weth after adding liquidity 2029.437812072234334060
        //    total dai after adding liquidity 6365315.562179444799799017
        //   ---- ratio  without distortion and adding liquidity ---- 3136
        //   Amount of WETH added after distortion: 0.500000000000000000
        //   Amount of DAI added after distortion: 1568.246024666283882496
        //   Liquidity tokens received : 12.961013437057530733
        //    total weth after distortion and adding liquidity 2129.937812072234334060
        //    total dai after distortion and adding liquidity 6366883.808204111083681513
        //   ---- ratio  with distortion and adding liquidity ---- 2989
        // distoration in the ratio .

        vm.startPrank(user);
        weth.deposit{value: 106e18}();
        weth.approve(address(router), 5e18);
        dai.approve(address(router), 10000e18); // approve 10000 DAI

        // direct transfer to pair contract to distort the ratio
        weth.transfer(pair, 100e18); // distorting the ratio by transferring 100 WETH directly to pair contract

        (uint256 amountA, uint256 amountB, uint256 liquidity2) = router.addLiquidity({
            tokenA: address(weth),
            tokenB: address(dai),
            amountADesired: 5e17,
            amountBDesired: 10000e18,
            amountAMin: 1,
            amountBMin: 1,
            to: user,
            deadline: block.timestamp + 1000
        });
        vm.stopPrank();

        console.log("Amount of WETH added after distortion:", amountA);
        console.log("Amount of DAI added after distortion:", amountB);
        console.log("Liquidity tokens received :", liquidity2);

        (uint256 reserve0Final, uint256 reserve1Final,) =
            IUniswapV2Pair(pair).getReserves();
        uint256 reserveAFinal;
        uint256 reserveBFinal;

        if (address(weth) < address(dai)) {
            reserveAFinal = reserve0Final;
            reserveBFinal = reserve1Final;
        } else {
            reserveAFinal = reserve1Final;
            reserveBFinal = reserve0Final;
        }

        console.log(
            " total weth after distortion and adding liquidity", reserveAFinal
        );
        console.log(
            " total dai after distortion and adding liquidity", reserveBFinal
        );
        console.log(
            "---- ratio  with distortion and adding liquidity ----",
            reserveBFinal / reserveAFinal
        );
    }

    function test_removeLiquidity() public {
        vm.deal(user, 10e18); // give user 10 WETH
        deal(address(dai), user, 20000e18); // give user 20000 DAI
        vm.startPrank(user);
        weth.deposit{value: 5e18}(); // deposit 5 WETH
        weth.approve(address(router), 5e18);
        dai.approve(address(router), 10000e18); // approve 10000 DAI
        (uint256 amount0, uint256 amount1, uint256 liquidity) = router.addLiquidity({
            tokenA: address(weth),
            tokenB: address(dai),
            amountADesired: 5e17,
            amountBDesired: 10000e18,
            amountAMin: 1,
            amountBMin: 1,
            to: user,
            deadline: block.timestamp + 1000
        });

        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(UNISWAP_V2_FACTORY)
                .getPair(address(weth), address(dai))
        );

        console.log(" weth token added ", amount0);
        console.log(" dai token added ", amount1);
        console.log("Liquidity tokens of users :", pair.balanceOf(user));

        pair.approve(address(router), liquidity);
        (uint256 amountA, uint256 amountB) = router.removeLiquidity({
            tokenA: address(weth),
            tokenB: address(dai),
            liquidity: liquidity,
            amountAMin: 1,
            amountBMin: 1,
            to: user,
            deadline: block.timestamp + 1000
        });
        vm.stopPrank();

        console.log("Amount of WETH removed:", amountA);
        console.log("Amount of DAI removed:", amountB);

        console.log(
            "Liquidity tokens of users after removal:", pair.balanceOf(user)
        );
    }
}
