// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import './IUniswapV2Pair.sol';
import './PriceFeed.sol';
import './Ownable.sol';
import './IPriceFeedFactory.sol';
import './UniswapV2Library.sol';
import './IERC20.sol';


contract PriceFeedBuyBacker is Ownable {

    IUniswapV2Pair public immutable swapPair;
    PriceFeed public immutable priceFeed;
    IERC20 public immutable buyWithToken;
    IERC20 public immutable buyBackToken;

    // the oracle price threshold that enables buyback
    uint public buyBackThreshold;
    // the amount of buyWithToken to use per buyback
    uint public buyWithAmount;

    event BuyBack(uint buyWithAmount, uint buyBackAmount, uint price);
    event SetBuyBackThreshold(uint buyBackThreshold);
    event SetBuyWithAmount(uint buyWithAmount);

    constructor(
        IPriceFeedFactory priceFeedFactory,
        IERC20 _buyWithToken,
        IERC20 _buyBackToken,
        uint _buyBackThreshold,
        uint _buyWithAmount
    ) {
        buyBackToken = _buyBackToken;
        buyWithToken = _buyWithToken;

        setBuyBackThreshold(_buyBackThreshold);
        setBuyWithAmount(_buyWithAmount);

        swapPair = IUniswapV2Pair(priceFeedFactory.getPair(address(buyWithToken), address(buyBackToken)));
        priceFeed = priceFeedFactory.getOracle(address(buyWithToken), address(buyBackToken));

        require(address(priceFeed) != address(0), "invalid price feed");
        require(address(swapPair) != address(0), "invalid swap pair");
    }

    function setBuyBackThreshold(uint _buyBackThreshold) public onlyOwner {
        buyBackThreshold = _buyBackThreshold;
        emit SetBuyBackThreshold(buyBackThreshold);
    }

    function setBuyWithAmount(uint _buyWithAmount) public onlyOwner {
        buyWithAmount = _buyWithAmount;
        emit SetBuyWithAmount(buyWithAmount);
    }

    function buyback() public returns (uint) {
        if (owner() != msg.sender) {
            // EOA and owner are allowed to trigger buyback
            // do not allow other contracts to trigger buyback as part of sandwich
            require(tx.origin == msg.sender, "buyback can only be triggered by an EOA");
        }

        // verify that the oracle price is below threshold
        uint price = priceFeed.consult();
        require(price < buyBackThreshold, "price is above threshold");

        // transfer the funds from the owner's wallet
        require(
            buyWithToken.transferFrom(owner(), address(swapPair), buyWithAmount),
            "failed to transfer to swap pair");

        uint buyBackAmount;
        if (address(buyWithToken) == swapPair.token0()) {
            (uint buyWithReserve, uint buyBackReserve,) = swapPair.getReserves();
            buyBackAmount = UniswapV2Library.getAmountOut(buyWithAmount, buyWithReserve, buyBackReserve);
            swapPair.swap(0, buyBackAmount, owner(), new bytes(0));
        } else {
            (uint buyBackReserve, uint buyWithReserve,) = swapPair.getReserves();
            buyBackAmount = UniswapV2Library.getAmountOut(buyWithAmount, buyWithReserve, buyBackReserve);
            swapPair.swap(buyBackAmount, 0, owner(), new bytes(0));
        }

        emit BuyBack(buyWithAmount, buyBackAmount, price);
        return buyBackAmount;
    }

    function recoverERC20(IERC20 token) external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}
