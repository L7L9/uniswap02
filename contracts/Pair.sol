// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Pair is ERC20{
    //工厂合约地址（为设置税等等）
    //目前没有用上
    address factory;

    //代币A地址
    address tokenA;
    //代币B地址
    address tokenB;
    //自身的地址
    address private thisAddr = address(this);

    //事件
    //增加流动性
    event LogAddLiquilty(address indexed user,uint256 _tokenA,uint256 _tokenB,uint256 liquilty);
    //取回流动性
    event LogBurn(address indexed user,uint256 _tokenA,uint256 _tokenB,uint256 liquilty);
    //交换代币
    event LogSwap(address indexed user, uint256 _tokenA,uint256 _tokenB);
    
    //设置工厂地址（可优化）
    constructor(address factoryAddress) ERC20("liquilty","LP") {
        factory = factoryAddress;
        _mint(factory, 0);
    }
    
    //防止重入攻击
    bool unlock = false;
    modifier lock(){
        require(!unlock,"unlock");
        unlock = true;
        _;
        unlock = false;
    }

    //用于第一次增加流动性
    modifier firstLiquilty(){
        require(totalSupply() > 0,"the pair doesn't have liquilty");
        _;
    }

    //初始化:在函数中初始化方便合约升级
    function initialize(address _tokenA,address _tokenB) external{
        require(msg.sender == factory,"you are not the owner");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    //增加流动性
    function addLiquilty(uint256 tokenAAmount,uint256 tokenBAmount) external lock{
        uint256 balanceA = getTokenBalance(tokenA,thisAddr);
        uint256 balanceB = getTokenBalance(tokenB,thisAddr);

        SafeERC20.safeTransferFrom(IERC20(tokenA), msg.sender, thisAddr, tokenAAmount);
        SafeERC20.safeTransferFrom(IERC20(tokenB), msg.sender, thisAddr, tokenBAmount);

        //LP币
        //用于表示流动性
        uint256 amount = tokenAAmount * tokenBAmount + (tokenAAmount * balanceB) + (tokenBAmount * balanceA);
        _mint(msg.sender,amount);
        emit LogAddLiquilty(msg.sender, balanceA + tokenAAmount, balanceB + tokenBAmount, amount);
    }

    //取回流动性
    function burn(uint256 LpAmount,address token) external lock firstLiquilty{
        require(LpAmount <= balanceOf(msg.sender),"the liquilty provided by you is not enough");
        
        //流动性
        uint256 totalSupply = totalSupply();

        if(LpAmount == totalSupply){
            _burn(msg.sender, LpAmount);
            _safeTransfer(tokenA, msg.sender, getTokenBalance(tokenA,thisAddr));
            _safeTransfer(tokenB, msg.sender, getTokenBalance(tokenB,thisAddr));
        }else{
            uint256 amount;
            if(token == tokenA){
                amount = getTokenBalance(token, thisAddr) - ((totalSupply - LpAmount) * (10 ** decimals()) / getTokenBalance(tokenB, thisAddr)) / (10 ** decimals());
            } else if(token == tokenB){
                amount = getTokenBalance(token, thisAddr) - ((totalSupply - LpAmount) * (10 ** decimals()) / getTokenBalance(tokenA, thisAddr)) / (10 ** decimals());
            }
            _burn(msg.sender, LpAmount);
            _safeTransfer(token, msg.sender, amount);
        }
        //中间可以增加返回利润的操作

        emit LogBurn(msg.sender, getTokenBalance(tokenA,thisAddr), getTokenBalance(tokenB,thisAddr), totalSupply);
    }

    //交换代币(不影响流动性K值的变化)
    //存在精度问题
    function swap(uint256 _tokenA,uint256 _tokenB) external lock firstLiquilty{
        require(_tokenA > 0 || _tokenB > 0,"amount should not be zero");
    
        //可以添加收手续费的操作

        uint256 liquilty = totalSupply();
        if(_tokenA > 0 ){
            SafeERC20.safeTransferFrom(IERC20(tokenA),msg.sender,thisAddr,_tokenA);

            uint256 amountB = getTokenBalance(tokenB, thisAddr) - (liquilty * 10 ** decimals() / (getTokenBalance(tokenA,thisAddr))) / 10 ** decimals();
            require(_safeTransfer(tokenB, msg.sender, amountB));
            _burn(msg.sender,liquilty - amountB * _tokenA);
        } else if(_tokenB > 0){
            SafeERC20.safeTransferFrom(IERC20(tokenB),msg.sender,thisAddr,_tokenB);

            uint256 amountA = getTokenBalance(tokenA, thisAddr) - (liquilty * 10 ** decimals() / (getTokenBalance(tokenB,thisAddr))) / 10 ** decimals();
            require(_safeTransfer(tokenA, msg.sender, amountA));
            _burn(msg.sender,liquilty - amountA * _tokenB);
        }

        emit LogSwap(msg.sender, _tokenA, _tokenB);
    }

    //用于代币输出
    function _safeTransfer(address token,address _to,uint256 _amount) internal returns(bool flag){
        flag = IERC20(token).transfer(_to, _amount);
    }

    //查看流动池储存量
    function getBalance() external view returns(uint256,uint256){
        uint256 amountA = getTokenBalance(tokenA, thisAddr);
        uint256 amountB = getTokenBalance(tokenB, thisAddr);
        return(amountA,amountB);
    }

    //获取调用者的代币量
    function getTokenBalance(address token,address addr) internal view returns(uint256 amount){
        amount = IERC20(token).balanceOf(addr);
    }
}