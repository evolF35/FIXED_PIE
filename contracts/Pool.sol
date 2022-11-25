
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract useChainLink {
    AggregatorV3Interface public priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x57241A37733983F97C4Ab06448F244A1E0Ca0ba8);
    }

    function getLatestPrice() public view returns (int){
        (,int price,,,) = priceFeed.latestRoundData();
        return(price);
    }

}

contract POS is ERC20, Ownable {
    constructor(string memory name) ERC20(name,"POS") {
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender,amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender,amount);
    }
}

contract NEG is ERC20, Ownable {
    constructor(string memory name) ERC20(name,"NEG") {
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender,amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender,amount);
    }
}


contract Pool {

    uint256 settlementDate;
    bool condition;

    POS public positiveSide;
    NEG public negativeSide;

    useChainLink public oracle;

    constructor() {
        settlementDate = block.timestamp + 10 seconds;
        positiveSide = new POS("ETHOVER");
        negativeSide = new NEG("ETHUNDER");
        condition = false;

        oracle = new useChainLink();
    }

    function depositToPOS() public payable {
        require(block.timestamp < settlementDate);
        require(msg.value > 0.001 ether, "more capital");
        positiveSide.mint(msg.value);
        positiveSide.transfer(msg.sender,msg.value);

//        console.log(positiveSide.balanceOf(msg.sender));
    }

    function depositToNEG() public payable {
        require(block.timestamp < settlementDate);
        require(msg.value > 0.001 ether, "more capital");
        negativeSide.mint(msg.value);
        negativeSide.transfer(msg.sender,msg.value);

//        console.log(negativeSide.balanceOf(msg.sender));

    }

    function settle() public {
        require(block.timestamp > settlementDate, "too early");
        int256 price = oracle.getLatestPrice();

//        console.logInt(price);

        if(price >= 2000){
            condition = true;
        }

    }

    function withdrawWithPOS() public { 
        require(block.timestamp > settlementDate, "too early");
        require(condition == true,"condition not satisfied");
        require(positiveSide.balanceOf(msg.sender) > 0, "you have nothing");

        uint256 saved = (positiveSide.balanceOf(msg.sender) / positiveSide.totalSupply()) * (address(this).balance);
        
//        console.log(saved);

        positiveSide.transferFrom(msg.sender,address(this),positiveSide.balanceOf(msg.sender));

//        console.log(positiveSide.balanceOf(msg.sender));

        (payable(msg.sender)).transfer(saved);
//        console.log(address(this).balance);
    }

    function withdrawWithNEG() public {
        require(block.timestamp > settlementDate, "too early");
        require(condition == false,"condition not satisfied");
        require(negativeSide.balanceOf(msg.sender) > 0, "you have nothing");

        uint256 saved = (negativeSide.balanceOf(msg.sender) / negativeSide.totalSupply()) * (address(this).balance);
        
        negativeSide.transferFrom(msg.sender,address(this),negativeSide.balanceOf(msg.sender));

 //       console.log(negativeSide.balanceOf(msg.sender));

        (payable(msg.sender)).transfer(saved);
 //       console.log(address(this).balance);

    }

}






