const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EDMC", function () {
    let EDMC, edmc;
    let owner, addr1, addr2, addrs;

    beforeEach(async function () {
        EDMC = await ethers.getContractFactory("EDMC");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        edmc = await EDMC.deploy();
        await edmc.deployed();
        await edmc.initialize("EDMC Token", "EDMC", ethers.utils.parseEther("1000000"));
    });

    describe("Deployment", function () {
        it("should deploy successfully", async function () {
            expect(edmc.address).to.properAddress; // Check if the contract has a valid Ethereum address
        });

        it("should mint initial supply to the owner", async function () {
            it("should mint initial supply to the owner", async function () {
                const initialSupply = ethers.utils.parseEther("500_000_000");
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
            const mintAmount = ethers.utils.parseUnits("100000", 5); // Using 5 decimals
            await edmc.mint(addr1.address, mintAmount);
            const addr1Balance = await edmc.balanceOf(addr1.address);
            expect(addr1Balance).to.equal(mintAmount);
        });

        it("should not mint beyond the maximum supply", async function () {
            const maxSupply = await edmc._maxSupply();
            const mintAmount = maxSupply.add(1); // One more than max supply
            await expect(edmc.mint(addr1.address, mintAmount)).to.be.revertedWith("Max supply exceeded");
        });
    });


    describe("Burning Functionality", function () {
        it("should burn tokens correctly", async function () {
            const burnAmount = ethers.utils.parseUnits("100000", 5); // Using 5 decimals
            await edmc.mint(owner.address, burnAmount); // Mint some tokens to burn

            const totalSupplyBeforeBurn = await edmc.totalSupply();
            await edmc.burn(burnAmount);
            const totalSupplyAfterBurn = await edmc.totalSupply();

            expect(totalSupplyBeforeBurn.sub(totalSupplyAfterBurn)).to.equal(burnAmount);
        });

        it("should not burn more tokens than an account holds", async function () {
            const burnAmount = ethers.utils.parseUnits("100000", 5); // Using 5 decimals
            // Assuming addr1 doesn't have enough tokens
            await expect(edmc.connect(addr1).burn(burnAmount)).to.be.reverted;
        });
    });


    describe("Fee Management", function () {
        it("should correctly set the fee percentage", async function () {
            const newFee = 5; // 5%
            await edmc.setFeePercentage(newFee);
            expect(await edmc.feePercentage()).to.equal(newFee);
        });

        it("should not set fee percentage beyond the maximum limit", async function () {
            const newFee = 11; // Exceeds the max limit
            await expect(edmc.setFeePercentage(newFee)).to.be.revertedWith("Fee exceeds the maximum limit");
        });

        it("should correctly collect fees on transfers", async function () {
            const transferAmount = ethers.utils.parseUnits("100000", 5);
            const feePercentage = await edmc.feePercentage();
            const expectedFee = transferAmount.mul(feePercentage).div(100);

            await edmc.mint(addr1.address, transferAmount);
            await edmc.connect(addr1).transfer(addr2.address, transferAmount);

            const feeCollectorBalance = await edmc.balanceOf(feeCollector);
            expect(feeCollectorBalance).to.equal(expectedFee);
        });
    });


    describe("Whitelist/Blacklist Functionality", function () {
        it("should add and remove an address from the whitelist", async function () {
            await edmc.addToWhitelist(addr1.address);
            expect(await edmc._feeWhitelist(addr1.address)).to.be.true;

            await edmc.removeFromWhitelist(addr1.address);
            expect(await edmc._feeWhitelist(addr1.address)).to.be.false;
        });

        it("should allow transfers from whitelisted addresses without fees", async function () {
            // ... Implementation ...
        });

        it("should add and remove an address from the blacklist", async function () {
            await edmc.addToBlacklist(addr1.address);
            expect(await edmc._transferBlacklist(addr1.address)).to.be.true;

            await edmc.removeFromBlacklist(addr1.address);
            expect(await edmc._transferBlacklist(addr1.address)).to.be.false;
        });

        it("should prevent transfers from blacklisted addresses", async function () {
            await edmc.addToBlacklist(addr1.address);
            const transferAmount = ethers.utils.parseUnits("100000", 5);
            await expect(edmc.connect(addr1).transfer(addr2.address, transferAmount)).to.be.revertedWith("Address is blacklisted");
        });
    });


    describe("Pause Functionality", function () {
        // ...
    });

    describe("Account Freezing", function () {
        // ...
    });

    describe("Upgradeability", function () {
        // ...
    });

    describe("Access Control", function () {
        // ...
    });

    describe("Edge Cases and Miscellaneous", function () {
        // ...
    });

    describe("Events", function () {
        // ...
    });
});
