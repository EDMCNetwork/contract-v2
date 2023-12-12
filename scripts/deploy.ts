import { ethers } from "hardhat";

async function main() {
  const EDMC = await ethers.getContractFactory("EDMC");

  const initialSupply = ethers.parseUnits("500_000_000", 8);

  const edmc = await EDMC.deploy();

  await edmc.waitForDeployment();
  await edmc.initialize("EDMC Token", "EDMC", initialSupply);

  console.log("EDMC deployed to:", edmc.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
