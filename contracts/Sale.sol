//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./EivissaProject.sol";
import "./IMRC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

contract Sale {
	uint256[3] public currentSupply;
	uint256[3] public maxSupplies;
	uint256[3] public minPrices;
	IMRC mrc;
	IERC20 usd;
	string name;
	bool public paused = true;
	bool public whitelistEnabled = true;
	mapping(address => bool) isAdmin;
	mapping(address => bool) whitelist;
	EivissaProject eivissa;

	modifier isNotPaused() {
		require(paused == false, "This sale is not running at the moment");
		_;
	}

	modifier onlyAdmin {
		require(isAdmin[msg.sender] == true, "Only admins can do this");
		_;
	}

	modifier whitelisted {
		require(whitelist[msg.sender] == true, "You are not whitelisted");
		_;
	}

	modifier onlyHolder {
		require(mrc.balanceOf(msg.sender) > 0 || isAdmin[msg.sender] == true, "Only holders can do this");
		_;
	}

	modifier onlyEivissa {
		require(msg.sender == address(eivissa), "This can only be done from the Eivissa contract");
		_;
	}

	constructor(EivissaProject eivissa_,
				uint256[3] memory maxSupplies_,
				uint256[3] memory minPrices_,
				string memory name_,
				IMRC mrc_,
				IERC20 usd_,
				address newAdmin) {
		eivissa = eivissa_;
		maxSupplies = maxSupplies_;
		minPrices = minPrices_;
		mrc = mrc_;
		usd = usd_;
		name = name_;
		isAdmin[address(eivissa)] = true;
		isAdmin[newAdmin] = true;
	}

	//PUBLIC

	function buy(uint256 id, uint256 price) public isNotPaused onlyHolder whitelisted {
		require(id < 3, "Invalid index");
		require(price >= minPrices[id], "Not enough price");
		require(currentSupply[id] < maxSupplies[id]);

		usd.transferFrom(msg.sender, address(eivissa), price);
		++(currentSupply[id]);
		eivissa.mint(msg.sender, id, price);
	}

	function playPause() public onlyAdmin {
		paused = !paused;
	}

	function finish() public onlyEivissa {
		usd.transfer(address(eivissa), usd.balanceOf(address(this)));
		selfdestruct(payable(address(eivissa)));
	}

	function addAdmin(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			isAdmin[newOnes[i]] = true;
	}

	function removeAdmin(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i) {
			if (newOnes[i] != msg.sender)
				isAdmin[newOnes[i]] = false;
		}
	}

	function addToWhitelist(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = true;
	}

	function removeFromWhitelist(address[] memory newOnes) public onlyAdmin {
		for (uint256 i = 0; i < newOnes.length; ++i)
			whitelist[newOnes[i]] = false;
	}

	receive() external payable {}
}
