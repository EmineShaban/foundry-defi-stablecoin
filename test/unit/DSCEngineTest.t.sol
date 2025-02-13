// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 amountToMint = 100 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /////////////////////
    //Constructor Tests//
    /////////////////////

    /////////////////////
    //Price Tests      //
    /////////////////////

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        // 15e18 ETH * $2000/ETH = $30,000e18
        uint256 expectedUsd = 30_000e18;
        uint256 usdValue = dsce.getUsdValue(weth, ethAmount);
        assertEq(usdValue, expectedUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        uint256 balanceBefore1 = dsc.balanceOf(USER);

        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        uint256 balanceBefore = dsc.balanceOf(USER);
        console.log("balanceBefore", balanceBefore);
        console.log("balanceBefore1",balanceBefore1); 
        console.log("USER", USER);
        console.log("weth", weth);
        console.log("AMOUNT_COLLATERAL", AMOUNT_COLLATERAL); 

        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, amountToMint);
          uint256 userBalance = dsc.balanceOf(USER);
        console.log("userBalance", userBalance);
        vm.stopPrank();
        _;
    }
 function testCanBurnDsc() public depositedCollateralAndMintedDsc {
        vm.startPrank(USER);
        dsc.approve(address(dsce), amountToMint);
        dsce.burnDsc(amountToMint);
        vm.stopPrank();

        uint256 userBalance = dsc.balanceOf(USER);
        console.log("userBalance", userBalance);
 
        assertEq(userBalance, 0);
    }
    // function testBurnDscReducesBalance() public depositCollateral{

    //     uint256 balanceBefore = dsc.balanceOf(USER);
    //     console.log("balanceBefore %d", balanceBefore);
    //     dsce.burnDsc(6);
    //     uint256 balanceAfter = dsc.balanceOf(USER);
    //      console.log("balanceAfter %d", balanceAfter);

    //     assertEq(balanceBefore - 500 * 1e18, balanceAfter);
    // }

    /*
    function testBurnDscReducesBalance() public {
        vm.startPrank(user);
        uint256 balanceBefore = dsc.balanceOf(user);
        engine.burnDsc(500 * 1e18);
        uint256 balanceAfter = dsc.balanceOf(user);
        assertEq(balanceBefore - 500 * 1e18, balanceAfter);
        vm.stopPrank();
    }

    function testBurnDscUpdatesMintedAmount() public {
        vm.startPrank(user);
        uint256 mintedBefore = engine.s_DSCMinted(user);
        engine.burnDsc(200 * 1e18);
        uint256 mintedAfter = engine.s_DSCMinted(user);
        assertEq(mintedBefore - 200 * 1e18, mintedAfter);
        vm.stopPrank();
    }

    function testBurnDscRevertsIfNotEnoughBalance() public {
        vm.startPrank(user);
        vm.expectRevert();
        engine.burnDsc(2000 * 1e18);
        vm.stopPrank();
    }

    function testBurnDscRevertsIfHealthFactorBroken() public {
        vm.startPrank(user);
        engine.mintDsc(900 * 1e18); // Уменьшаем health factor
        vm.expectRevert();
        engine.burnDsc(800 * 1e18); // Приведет к нарушению health factor
        vm.stopPrank();
    }

    */
}
