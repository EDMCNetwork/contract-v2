const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EDMC", function () {
    let EDMC, edmc;
    let owner, addr1, addr2, addrs;

    beforeEach(async function () {
        EDMC = await ethers.getContractFactory("EDMC");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        edmc = await EDMC.deploy();
        await edmc.waitForDeployment();
        await edmc.initialize("EDMC Token", "EDMC", ethers.parseUnits("1000000", 8));
    });

    describe("Deployment", function () {
        it("should deploy successfully", async function () {
            expect(edmc.target).to.properAddress; // Check if the contract has a valid Ethereum address
        });

        it("should mint initial supply to the owner", async function () {
            it("should mint initial supply to the owner", async function () {
                const initialSupply = ethers.parseUnits("500000000", 8);
                const ownerBalance = await edmc.balanceOf(owner.address);
                expect(ownerBalance).to.equal(initialSupply);
            });
        });

        it("should set the correct owner", async function () {
            expect(await edmc.owner()).to.equal(owner.address);
        });
    });

    describe("Minting Functionality", function () {
        it("should mint new tokens correctly", async function () {
            const mintAmount = ethers.parseUnits("100000", 8);
            await edmc.mint(addr1.address, mintAmount);
            const addr1Balance = await edmc.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(mintAmount);
        });

        it("should not mint beyond the maximum supply", async function () {
            const maxSupply = await edmc.maxSupply();
            const mintAmount = maxSupply + BigInt(1);
            await expect(edmc.mint(addr1.address, mintAmount)).to.be.revertedWith("Max supply exceeded");
        });
    });


    describe("Burning Functionality", function () {
        it("should burn tokens correctly", async function () {
            const burnAmount = ethers.parseUnits("100000", 8);
            await edmc.mint(owner.address, burnAmount);

            const totalSupplyBeforeBurn = await edmc.totalSupply();
            await edmc.burn(burnAmount);
            const totalSupplyAfterBurn = await edmc.totalSupply();

            expect(totalSupplyBeforeBurn - BigInt(totalSupplyAfterBurn)).to.equal(burnAmount);
        });

        it("should not burn more tokens than an account holds", async function () {
            const burnAmount = ethers.parseUnits("100000", 8); // Using 5 decimals
            // Assuming addr1 doesn't have enough tokens
            await expect(edmc.connect(addr1).burn(burnAmount)).to.be.reverted;
        });
    });


    describe("Fee Management", function () {
        it("should correctly set the fee percentage", async function () {
            const newFee = 3;
            await edmc.setFeePercentage(newFee);
            expect(await edmc.feePercentage()).to.equal(newFee);
        });

        it("should not set fee percentage beyond the maximum limit", async function () {
            const newFee = 11; // Exceeds the max limit
            await expect(edmc.setFeePercentage(newFee)).to.be.revertedWith("Fee exceeds the maximum limit");
        });

        it("should correctly collect fees on transfers", async function () {
            const transferAmount = ethers.parseUnits("100000", 8);
            const feePercentage = await edmc.feePercentage();

            const feeCollectorBalanceStart = await edmc.balanceOf(owner.address);
            const expectedFee = (transferAmount * BigInt(feePercentage)) / BigInt(100);

            await edmc.mint(addr1.address, transferAmount);
            await edmc.connect(addr1).transfer(addr2.address, transferAmount);

            const feeCollectorBalance = await edmc.balanceOf(owner.address);
            expect(feeCollectorBalance).to.equal(feeCollectorBalanceStart + expectedFee);
        });
    });


    describe("Whitelist/Blacklist Functionality", function () {
        it("should add and remove an address from the whitelist", async function () {
            await edmc.addToWhitelist(addr1.address);
            expect(await edmc.feeWhitelist(addr1.address)).to.be.true;

            await edmc.removeFromWhitelist(addr1.address);
            expect(await edmc.feeWhitelist(addr1.address)).to.be.false;
        });

        it("should allow transfers from whitelisted addresses without fees", async function () {
            // Whitelist an address
            await edmc.addToWhitelist(addr1.address);

            // Mint tokens to the whitelisted address
            const mintAmount = ethers.parseUnits("1000", 8);
            await edmc.mint(addr1.address, mintAmount);

            // Transfer tokens from the whitelisted address
            const transferAmount = ethers.parseUnits("100", 8);
            await edmc.connect(addr1).transfer(addr2.address, transferAmount);

            // Get the final balance of the recipient
            const finalBalance = await edmc.balanceOf(addr2.address);

            // Check if the recipient received the exact transfer amount (indicating no fees were deducted)
            expect(finalBalance.toString()).to.equal(transferAmount.toString());
        });


        it("should add and remove an address from the blacklist", async function () {
            await edmc.addToBlacklist(addr1.address);
            expect(await edmc.transferBlacklist(addr1.address)).to.be.true;

            await edmc.removeFromBlacklist(addr1.address);
            expect(await edmc.transferBlacklist(addr1.address)).to.be.false;
        });

        it("should prevent transfers from blacklisted addresses", async function () {
            await edmc.addToBlacklist(addr1.address);
            const transferAmount = ethers.parseUnits("100000", 8);
            await expect(edmc.connect(addr1).transfer(addr2.address, transferAmount)).to.be.revertedWith("Sender address is blacklisted");
        });
    });


    describe("Pause Functionality", function () {
        it("should pause and unpause token transfers", async function () {
            await edmc.pause();
            await expect(edmc.transfer(addr1.address, 100)).to.be.reverted;

            await edmc.unpause();
            await expect(edmc.transfer(addr1.address, 100)).to.not.be.reverted;
        });
    });

    describe("Upgradeability", function () {
        // ...
    });

    describe("Access Control", function () {
        it("should restrict access to onlyOwner functions", async function () {
            await expect(edmc.connect(addr1).pause()).to.be.reverted;
        });
    });

    describe("Edge Cases and Miscellaneous", function () {
        // ...
    });

    describe("Events", function () {
        it("should emit events correctly", async function () {
            await expect(edmc.setFeePercentage(2))
                .to.emit(edmc, "FeePercentageChanged")
                .withArgs(2);

            // Test other events similarly
        });
    });
});
