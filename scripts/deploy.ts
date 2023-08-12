import { ethers, upgrades } from "hardhat";

async function main() {
  const Maskie = await ethers.getContractFactory("Maskie");
  console.log("Deploying Maskie...");
  const maskie = await upgrades.deployProxy(Maskie);
  await maskie.waitForDeployment();
  console.log("Maskie deployed to:", maskie.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
