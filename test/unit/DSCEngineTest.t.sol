// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDCS} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDCS deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDCS();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkCofig();
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

    function testRevertsWithUnapprovedCollateral() public{
        ERC20Mock ranToken = new ERC20Mock();
            vm.startPrank(USER);
            vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
            dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
                vm.stopPrank();


    }

modifier depositCollateral{
    vm.startPrank(USER);
    ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
    dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
    vm.stopPrank();
    _;
}
    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral{
 (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccounttInformation(USER);
    uint256 expectedTotalDscMinted = 0;
    uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
    assertEq(totalDscMinted, expectedTotalDscMinted);
    assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);

    }
}
