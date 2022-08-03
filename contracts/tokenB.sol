// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

/**
 * uniswap内部的流通货币
 * 用于用户增加流通性后给予的利润
 */
contract tokenB is ERC20,Ownable{
    constructor() ERC20("tokenB","tokenB"){
        transferOwnership(_msgSender());
        uint256 initSupply = 10**8;
        _mint(_msgSender(), initSupply);
    }

    function addSupply(uint256 supply) public onlyOwner{
        _mint(_msgSender(), supply);
    }

    function getToken(uint256 amount) public {
        transferFrom(owner(), _msgSender(), amount);
    }

    function getAddress() public view returns(address){
        return address(this);
    }
}
