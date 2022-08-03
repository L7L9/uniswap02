// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Pair.sol";

contract Factory{
    //创建币对事件
    event LogCreatePair(address indexed pairAddress,address tokenA,address tokenB);

    //通过代币地址查询币对地址
    mapping(address => mapping(address => address)) pairAddresses;
    
    //用于保存所有币对的地址
    address[] public allPairs;

    //判断代币合约是否相同，是否为0
    modifier checkPair(address tokenA,address tokenB){
        require(tokenA != tokenB,"token can not be the same");
        require(tokenA != address(0) && tokenB != address(0),"token address can not be zero");
        _;
    }

    //创建币对
    function createPair(address tokenA,address tokenB,address newPair) external checkPair(tokenA,tokenB){
        require(pairAddresses[tokenA][tokenB] == address(0),"the pair has been existed");

        //在web3.js部署合约，在这里取得对象
        Pair pair = Pair(newPair);
        
        //初始化
        pair.initialize(tokenA, tokenB);

        address pairAddress = address(pair);

        //保存
        allPairs.push(pairAddress);
        pairAddresses[tokenA][tokenB] = pairAddress;
        pairAddresses[tokenB][tokenA] = pairAddress; 

        emit LogCreatePair(pairAddress, tokenA, tokenB);
    }

    //获取币对地址
    function getPairAddress(address tokenA,address tokenB) external view checkPair(tokenA,tokenB) returns(address){
        require(pairAddresses[tokenA][tokenB] != address(0),"the pair does not existed");
        return pairAddresses[tokenA][tokenB];
    }

    //如果存在币对，返回第一个币对
    function getDefaultPair() external view returns(bool,address){
        address defaultPair = address(0);
        bool flag = false;
        if(allPairs.length > 0){
            defaultPair = allPairs[0];
            flag = true;
        }
        return (flag,defaultPair);
    }

    //返回所有币对
    function getAllPairs() external view returns(address[] memory){
        return allPairs;
    }
}