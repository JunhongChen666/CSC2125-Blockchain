// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Uncomment this line to use console.log
import "hardhat/console.sol";

contract SampleCoin is ERC20 {
    
    address public owner;
    // your code goes here (you can do it!)
     constructor() ERC20("SampleCoin", "SPC") {
        //18 wei
        //1 ERCtoken = 10**18 units
        //initialize 1000 ERCtokens
        owner = msg.sender;
        _mint(msg.sender, 100 * (10 ** uint256(decimals())));
    }

}