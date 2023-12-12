// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


/**
 * @notice EDMC is an ERC20 token with extended functionalities:
 * - It can be paused and unpaused by the owner, halting all transfers when paused.
 * - It includes a burn function allowing users to burn their tokens.
 * - The contract is upgradeable using UUPS (Universal Upgradeable Proxy Standard).
 * - It implements a fee mechanism, charging a fee on transfers, which is customizable and can be updated by the owner.
 * - The contract includes a maximum supply limit, ensuring no more than a fixed amount of tokens can ever exist.
 * - It features a whitelist system where addresses can be exempted from paying transfer fees.
 * - Additionally, it has a blacklist functionality to restrict certain addresses from performing transfers.
 *
 * @dev This contract uses OpenZeppelin's libraries for standardized, secure, and tested implementations of ERC20, Ownable, and Pausable functionalities.
 * The contract is initialized with a name, symbol, and initial supply of tokens. The initialization also sets up the owner and prepares the contract for upgrades.
 * For security and functionality, the contract restricts certain actions to the owner and enforces checks like maximum supply, transfer blacklist.
 * The fee mechanism and whitelist/blacklist can be managed by the owner, providing flexibility in the contract's behavior.
 */
contract EDMC is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable {

    /// @dev Maximum permissible fee percentage that can be set for transactions.
    uint256 private _maxFee = 4;

    /// @dev Mapping to keep track of addresses that are exempt from transaction fees.
    mapping(address => bool) public feeWhitelist;

    /// @dev Mapping to keep track of addresses that are blacklisted from performing transfers.
    mapping(address => bool) public transferBlacklist;

    /// @notice The percentage of each transaction taken as a fee.
    /// @dev Fee percentage for transactions, charged if the address is not in the fee whitelist.
    uint256 public feePercentage = 3;

    /// @notice The collector address where transaction fees are sent.
    /// @dev Address where the transaction fees are accumulated.
    address public feeCollector;

    /// @dev Maximum supply of tokens that can ever exist for this token.
    uint256 public maxSupply = 500_000_000 * 10**8;

    /// @dev Emitted when the fee percentage is changed.
    /// @param newFeePercentage The new transaction fee percentage.
    event FeePercentageChanged(uint256 newFeePercentage);

    /// @dev Emitted when the fee collector address is updated.
    /// @param newFeeCollector The address of the new fee collector.
    event FeeCollectorChanged(address newFeeCollector);

    /// @dev Emitted when an address is added to the whitelist.
    /// @param _address The address that was added to the whitelist.
    event WhitelistedAddressAdded(address indexed _address);

    /// @dev Emitted when an address is removed from the whitelist.
    /// @param _address The address that was removed from the whitelist.
    event WhitelistedAddressRemoved(address indexed _address);

    /// @dev Emitted when an address is added to the blacklist.
    /// @param _address The address that was added to the blacklist.
    event BlacklistedAddressAdded(address indexed _address);

    /// @dev Emitted when an address is removed from the blacklist.
    /// @param _address The address that was removed from the blacklist.
    event BlacklistedAddressRemoved(address indexed _address);

    /// @dev Emitted when an account is frozen.
    /// @param _address The address of the account that was frozen.
    event AccountFrozen(address indexed _address);

    /// @dev Emitted when an account is unfrozen.
    /// @param _address The address of the account that was unfrozen.
    event AccountUnfrozen(address indexed _address);

    /// @notice Initializes the contract with a name, symbol, and initial supply of the token.
    /// @dev This initializer replaces the constructor for upgradeable contracts.
    /// It initializes the base ERC20 contract, sets up ownership, and mints the initial supply to the deployer.
    /// It can only be called once, as enforced by the `initializer` modifier.
    /// @param name The name of the token.
    /// @param symbol The symbol (ticker) of the token.
    /// @param initialSupply The amount of tokens to mint upon initialization.
    function initialize(string memory name, string memory symbol, uint256 initialSupply) public initializer {
        __ERC20_init(name, symbol);  // Initialize the ERC20 base contract.
        __Ownable_init(msg.sender);            // Initialize the Ownable module.
        __UUPSUpgradeable_init();    // Initialize the UUPS upgradeable module.
        __Pausable_init();           // Initialize the Pausable module.
        __ERC20Burnable_init();      // Initialize the ERC20 burnable module.

        _mint(msg.sender, initialSupply);  // Mint the initial supply to the message sender.
        feeCollector = msg.sender;         // Set the fee collector to the message sender.
    }

    /// @dev Returns the number of decimal places the token uses.
    /// @return The number of decimal places (5 for this token).
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    /// @notice Sets a new transaction fee percentage.
    /// @dev Only callable by the contract owner and the fee must not exceed the maximum limit.
    /// @param newFee The new transaction fee percentage to be set.
    function setFeePercentage(uint256 newFee) public onlyOwner {
        require(newFee <= _maxFee, "Fee exceeds the maximum limit");
        feePercentage = newFee;
        emit FeePercentageChanged(newFee);
    }

    /// @notice Sets a new fee collector address.
    /// @dev Only callable by the contract owner.
    /// @param newCollector The address of the new fee collector.
    function setFeeCollector(address newCollector) public onlyOwner {
        feeCollector = newCollector;
        emit FeeCollectorChanged(newCollector);
    }

    /// @notice Adds an address to the fee whitelist.
    /// @dev Only callable by the contract owner.
    /// @param _address The address to be added to the whitelist.
    function addToWhitelist(address _address) public onlyOwner {
        feeWhitelist[_address] = true;
        emit WhitelistedAddressAdded(_address);
    }

    /// @notice Removes an address from the fee whitelist.
    /// @dev Only callable by the contract owner.
    /// @param _address The address to be removed from the whitelist.
    function removeFromWhitelist(address _address) public onlyOwner {
        feeWhitelist[_address] = false;
        emit WhitelistedAddressRemoved(_address);
    }

    /// @notice Adds an address to the transfer blacklist.
    /// @dev Only callable by the contract owner.
    /// @param _address The address to be added to the blacklist.
    function addToBlacklist(address _address) public onlyOwner {
        transferBlacklist[_address] = true;
        emit BlacklistedAddressAdded(_address);
    }

    /// @notice Removes an address from the transfer blacklist.
    /// @dev Only callable by the contract owner.
    /// @param _address The address to be removed from the blacklist.
    function removeFromBlacklist(address _address) public onlyOwner {
        transferBlacklist[_address] = false;
        emit BlacklistedAddressRemoved(_address);
    }

    /// @notice Pauses all token transfers.
    /// @dev This function is only callable by the contract owner and halts all token transfers while the contract is paused.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the token transfers.
    /// @dev This function is only callable by the contract owner and resumes token transfers after being paused.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev Mints tokens to a specified account.
    /// This internal function is an override of the base ERC20 `_mint` function.
    /// It includes an additional check to ensure that the minting does not exceed the maximum supply.
    /// @param account The address that will receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address account, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _mint(account, amount);
    }

    function _update(address from, address to, uint256 value) internal override whenNotPaused {
        if (from == address(0)) { // Minting tokens
            require(totalSupply() + value <= maxSupply, "Max supply exceeded");
        }

        uint256 feeAmount = 0;

        // Check for fees if it's a normal transfer (neither minting nor burning)
        if (from != address(0) && to != address(0)) {
            require(!transferBlacklist[from], "Sender address is blacklisted");
            require(!transferBlacklist[to], "Recipient address is blacklisted");

            // Calculate fees if neither party is whitelisted
            if (!feeWhitelist[from] && !feeWhitelist[to]) {
                feeAmount = (value * feePercentage) / 100;

                // Ensure there is enough balance to cover the fee
                require(value >= feeAmount, "Insufficient balance to cover fees");

                value -= feeAmount; // Reduce the transfer value by the fee amount
            }
        }

        // Call the original _update function for the main transfer
        super._update(from, to, value);

        // Handle fee transfer separately if applicable
        if (feeAmount > 0) {
            // Transfer the fee from the sender to the fee collector
            super._update(from, feeCollector, feeAmount);
        }
    }

    /// @dev Authorizes an upgrade to a new implementation contract.
    /// This internal function is called by the UUPS proxy pattern and ensures that only the contract owner can perform upgrades.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}