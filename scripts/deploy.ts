import { ethers } from "hardhat";

async function main() {
  const EDMC = await ethers.getContractFactory("EDMC");

  const initialSupply = ethers.parseUnits("500_000_000", 8);

  const edmc = await EDMC.deploy(
      "EDMC Network", // Token Name
      "EDMC",       // Token Symbol
      initialSupply // Initial Supply
  );

  await edmc.deployed();

  console.log("EDMC deployed to:", edmc.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
