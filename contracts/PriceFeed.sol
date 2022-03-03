// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import './IUniswapV2Pair.sol';
import './ISlidingWindowOracle.sol';


interface ERC20 {
    function decimals() external view returns(uint8);
}


contract PriceFeed {
    address public immutable tokenIn;
    address public immutable tokenOut;
    uint public immutable oneToken;
    ISlidingWindowOracle public immutable slidingWindowOracle;

    constructor(address _tokenIn, address _tokenOut, ISlidingWindowOracle _slidingWindowOracle) {
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        slidingWindowOracle = _slidingWindowOracle;
        oneToken = uint(10)**(ERC20(tokenIn).decimals());
    }

    function consult() external view returns (uint) {
        return slidingWindowOracle.consult(tokenIn, oneToken, tokenOut);
    }
}
