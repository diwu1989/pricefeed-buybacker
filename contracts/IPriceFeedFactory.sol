// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import './PriceFeed.sol';


interface IPriceFeedFactory {
    function pairs() external view returns (address[] memory);
    function getPair(address tokenA, address tokenB) external view returns (address);
    function getOracle(address tokenA, address tokenB) external view returns (PriceFeed);
    function workable() external view returns (bool);
}
