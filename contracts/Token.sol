// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MyToken is Initializable, ERC20, ERC20Burnable, Ownable, UUPSUpgradeable {
    uint256 private _maxSupply = 1_000_000 * 10**18;
    mapping(address => bool) private _feeWhitelist;
    mapping(address => bool) private _transferBlacklist;
    mapping(address => bool) private _frozenAccount;

    uint256 public feePercentage = 3;
    address public feeCollector;

    event FeePercentageChanged(uint256 newFeePercentage);
    event FeeCollectorChanged(address newFeeCollector);
    event WhitelistedAddressAdded(address indexed _address);
    event WhitelistedAddressRemoved(address indexed _address);
    event BlacklistedAddressAdded(address indexed _address);
    event BlacklistedAddressRemoved(address indexed _address);
    event AccountFrozen(address indexed _address);
    event AccountUnfrozen(address indexed _address);


    function initialize(string memory name, string memory symbol, uint256 initialSupply) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        _mint(msg.sender, initialSupply);
        feeCollector = msg.sender;
    }

    function setFeePercentage(uint256 newFee) public onlyOwner {
        feePercentage = newFee;
        emit FeePercentageChanged(newFee);
    }

    function setFeeCollector(address newCollector) public onlyOwner {
        feeCollector = newCollector;
        emit FeeCollectorChanged(newCollector);
    }

    function addToWhitelist(address _address) public onlyOwner {
        _feeWhitelist[_address] = true;
        emit WhitelistedAddressAdded(_address);
    }


    function removeFromWhitelist(address _address) public onlyOwner {
        _feeWhitelist[_address] = false;
        emit WhitelistedAddressRemoved(_address);
    }


    function addToBlacklist(address _address) public onlyOwner {
        _transferBlacklist[_address] = true;
        emit BlacklistedAddressAdded(_address);
    }


    function removeFromBlacklist(address _address) public onlyOwner {
        _transferBlacklist[_address] = false;
        emit BlacklistedAddressRemoved(_address);
    }


    function freezeAccount(address _address) public onlyOwner {
        _frozenAccount[_address] = true;
        emit AccountFrozen(_address);
    }

    function unfreezeAccount(address _address) public onlyOwner {
        _frozenAccount[_address] = false;
        emit AccountUnfrozen(_address);
    }


    function _mint(address account, uint256 amount) internal override {
        require(totalSupply() + amount <= _maxSupply, "Max supply exceeded");
        super._mint(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!_transferBlacklist[sender] && !_transferBlacklist[r    ecipient], "Address is blacklisted");
        require(!_frozenAccount[sender], "Sender account is frozen");
        require(!_frozenAccount[recipient], "Recipient account is frozen");

        uint256 feeAmount = 0;
        if (!_feeWhitelist[sender] && !_feeWhitelist[recipient]) {
            feeAmount = (amount * feePercentage) / 100;
            amount -= feeAmount;
        }

        super._transfer(sender, recipient, amount);

        if (feeAmount > 0) {
            super._transfer(sender, feeCollector, feeAmount);
        }
    }


    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}