# EDMC Token Contract

## Overview
The EDMC token is an ERC20-compliant token with extended functionalities. This contract is implemented using Solidity and is designed for EVM-based blockchains. The token includes various features such as pausing/unpausing transfers, token burning, a fee mechanism, and upgradeability using UUPS.

## Features

- **Pause Functionality**: The contract can be paused and unpaused by the owner, halting all transfers when paused.
- **Burn Functionality**: Users are allowed to burn their tokens, reducing the total supply.
- **Upgradeable**: The contract is upgradeable using the Universal Upgradeable Proxy Standard (UUPS), allowing for future improvements and updates.
- **Fee Mechanism**: A fee mechanism is implemented for transfers, which can be updated by the owner.
- **Maximum Supply Limit**: The contract enforces a maximum token supply, ensuring no more tokens than the specified limit can ever exist.
- **Whitelist/Blacklist**: Addresses can be whitelisted to be exempted from transfer fees or blacklisted to restrict them from performing transfers.
- **Decimals**: The token uses 8 decimal places.

## Contract Details

- **Token Name**: EDMC Token
- **Symbol**: EDMC
- **Decimals**: 8
- **Maximum Supply**: 500,000,000 EDMC

## Functions

### Owner Functions
- `pause()`: Pauses all token transfers.
- `unpause()`: Unpauses the token transfers.
- `setFeePercentage(uint256)`: Sets the transaction fee percentage.
- `setFeeCollector(address)`: Sets the address where transaction fees are sent.
- `addToWhitelist(address)`: Adds an address to the fee whitelist.
- `removeFromWhitelist(address)`: Removes an address from the fee whitelist.
- `addToBlacklist(address)`: Adds an address to the transfer blacklist.
- `removeFromBlacklist(address)`: Removes an address from the transfer blacklist.
- `_authorizeUpgrade(address)`: Authorizes an upgrade to a new implementation contract.

### Public Functions
- `burn(uint256)`: Allows users to burn their tokens.
- `transfer(address, uint256)`: Transfers tokens to a specified address, applying fee and blacklist/whitelist logic.

## Environment Setup
Before deploying and verifying the EDMC token contract, it's crucial to set up your environment variables correctly. These variables are essential for interacting with Ethereum nodes and the Etherscan API. Follow the steps below to configure your .env file:

### Using the .env.example File
1. Locate the .env.example File: This file is located in the root directory of your project.

2. Create a .env File: Copy the .env.example file and rename the copy to .env. This file will be used to store your private environment variables.

3. Set Your Environment Variables: Open the .env file and fill in the following variables:

    - `INFURA_PROJECT_ID`: Your Infura project ID. This is required to access the Ethereum network.
    - `PRIVATE_KEY`: Your Ethereum private key. This key is used for deploying and interacting with the smart contract.
    - `ETHERSCAN_API`: Your Etherscan API key. This is required for verifying your contract on Etherscan.

## Deployment

This contract should be deployed on an EVM-based blockchain. Make sure to set the initial supply, token name, and symbol upon deployment.

### Deployment Script
A deployment script is provided in the scripts directory (deploy.ts). This script automates the process of deploying the EDMC contract to the blockchain.

To deploy the contract, run the following command, replacing <networkName> with the desired network:

```bash
npx hardhat run scripts/deploy.ts --network <networkName>
```

### Verifying Contract on Etherscan

After deploying your smart contract to the Ethereum network, you can verify it on Etherscan to make the source code visible and verifiable by others. Here's how to do it:

 **Run the Verification Command**:
   Use the Hardhat command to verify the contract. Replace `CONTRACT_ADDRESS` with the deployed contract's address and provide the constructor arguments if any. The command format is as follows:

   ```bash
   npx hardhat verify --network <networkName> CONTRACT_ADDRESS [CONSTRUCTOR_ARGUMENTS]
   ```

For example:
```bash
npx hardhat verify --network polygon DEPLOYED_CONTRACT_ADDRESS "EDMC Network" "EDMC" "50000000000000000"
```
 