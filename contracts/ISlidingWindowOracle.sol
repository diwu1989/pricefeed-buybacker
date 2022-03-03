// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;


interface ISlidingWindowOracle {
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
    function update(address tokenA, address tokenB) external;
    function periodSize() external view returns (uint);
}
