import Web3 from "web3";
import factoryArtifacts from "../../build/contracts/Factory.json";
import pairArtifacts from "../../build/contracts/Pair.json";
import tokenAArtifacts from "../../build/contracts/tokenA.json";
import tokenBArtifacts from "../../build/contracts/tokenB.json";

const App = {
  web3: null,
  account: null,
  factory: null,
  tokenA:null,
  tokenB:null,
  pair:null,

  start: async function() {
    const { web3 } = this;

    try {
      // get contract instance
      const networkId = await web3.eth.net.getId();
      
      this.factory = await new web3.eth.Contract(
        factoryArtifacts.abi,
        factoryArtifacts.networks[networkId].address,
      );

      this.tokenA = new web3.eth.Contract(
        tokenAArtifacts.abi,
        tokenAArtifacts.networks[networkId].address,
      );
      this.tokenB = new web3.eth.Contract(
        tokenBArtifacts.abi,
        tokenBArtifacts.networks[networkId].address,
      );
      this.refreashPair();

      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },

  refreashPair: async function(){
    const result = await this.factory.methods.getAllPairs().call();
    if(result.length > 0){
      for(var pair in result){
        const pairs = document.getElementById("pair");
        var option = document.createElement("option");
        option.appendChild(document.createTextNode(result[pair]));
        option.setAttribute("value",result[pair]);
        pairs.appendChild(option);
      }
    }
  },

  setPair: async function(){
    const pairAddress = document.getElementById("pair").value;
    this.pair = new this.web3.eth.Contract(
      pairArtifacts.abi,
      pairAddress
    );
    alert("设置成功");
  },

  //获取A币地址
  getAAddress: async function(){
    const { getAddress } = this.tokenA.methods;
    await getAddress().call().then(function(result){console.log(result)});
    const { balanceOf } = this.tokenA.methods;
    await balanceOf(this.account).call().then(function(result){console.log(result)});
  },

  //获取B币地址
  getBAddress: async function(){
    const { getAddress } = this.tokenB.methods;
    await getAddress().call().then(function(result){console.log(result)});
    const { balanceOf } = this.tokenB.methods;
    await balanceOf(this.account).call().then(function(result){console.log(result)});
  },

  //获取当前账号
  getAccount: async function(){
    console.log(this.account);
  },

  //获取币对地址
  getPairAddress: async function(){
    const { getPairAddress } = this.factory.methods;

    const addressA = document.getElementById("tokenA").value;
    const addressB = document.getElementById("tokenB").value;

    const result = await getPairAddress(addressA,addressB).call();
    console.log(result);
  },

  //获取当前用户的流动性
  getLpAmount: async function(){
    if(pair == null){
      alert("当前没有币对合约");
      return;
    }
    await this.pair.methods.balanceOf(this.account).call().then(function(result){
      console.log(result);
    });
  },

  //获取交易池内的余额
  getBalance: async function(){
    if(pair == null){
      alert("当前没有币对合约");
      return;
    }
    const result = this.pair.methods.getBalance().call();
    console.log(result);
  },

  //创建币对
  createPair: async function(){
    const newPair = new this.web3.eth.Contract(
      pairArtifacts.abi
    );
    const thisPair = await newPair.deploy({
      data:pairArtifacts.bytecode,
      arguments:[this.factory.options.address]
    }).send({
      gas: 3000000,
      from: this.account
    });
    const { createPair } = this.factory.methods;

    const addressA = document.getElementById("tokenA").value;
    const addressB = document.getElementById("tokenB").value;

    await createPair(addressA,addressB,thisPair.options.address).send({
      gas: 2000000,
      from: this.account
    }).then(function(result){
      console.log(result);
      alert("建立成功");
    });
    this.refreashPair();
  },

  //增加流动性
  addLiquilty: async function(){
    if(pair == null){
      alert("当前没有币对合约");
      return;
    }
    const liquiltyA = document.getElementById("liquiltyA").value;
    const liquiltyB = document.getElementById("liquiltyB").value;

    await this.tokenA.methods.approve(this.pair.options.address,liquiltyA).send({
      gas:1000000,
      from: this.account
    }).then(function(result){console.log(result)});
    await this.tokenB.methods.approve(this.pair.options.address,liquiltyB).send({
      gas:1000000,
      from: this.account
    }).then(function(result){console.log(result)});
    await this.pair.methods.addLiquilty(liquiltyA,liquiltyB).send({
      gas:1000000,
      from: this.account
    }).then(function(result){
      console.log(result);
      alert("添加成功");
    });
  },

  //取回流动性
  burn: async function(){
    if(pair == null){
      alert("当前没有币对合约");
      return;
    }
    const lpAmount = document.getElementById("lpAmount").value;
    const choose = document.getElementById("getToken").value;
    if(choose == "A"){
      const address = this.tokenA.options.address;
      await this.pair.methods.burn(lpAmount,address).send({
        gas:1000000,
        from: this.account
      }).then(function(result){
        console.log(result);
      })
    } else if(choose == "B"){
      const address = this.tokenB.options.address;
      await this.pair.methods.burn(lpAmount,address).send({
        gas:1000000,
        from: this.account
      }).then(function(result){
        console.log(result);
      })
    }
  },

  //代币交换
  swap: async function(){
    if(pair == null){
      alert("当前没有币对合约");
      return;
    }
    const choose = document.getElementById("token").value;

    const amount = document.getElementById("exchangeAmount").value;

    if(choose == "A"){
      await this.tokenB.methods.approve(this.pair.options.address,amount).send({
        gas:1000000,
        from: this.account
      }).then(function(result){console.log(result)});
      await this.pair.methods.swap(0,amount).send({
        gas:1000000,
        from:this.account
      }).then(function(result){console.log(result)});
    } else if(choose == "B"){
      await this.tokenA.methods.approve(this.pair.options.address,amount).send({
        gas:1000000,
        from: this.account
      }).then(function(result){console.log(result)});
      await this.pair.methods.swap(amount,0).send({
        gas:1000000,
        from:this.account
      }).then(function(result){console.log(result)});
    }else {
      alert("请选择要获取的代币");
    }
  },
};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
