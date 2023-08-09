import { ethers, upgrades } from "hardhat";

async function main() {
  const Maskie = await ethers.getContractFactory("Maskie");
  console.log("Deploying Maskie...");
  const maskie = await upgrades.deployProxy(Maskie, [
    "0x79216912Bc403080f80a4c995f1163Df8239568b",
    "0x79216912Bc403080f80a4c995f1163Df8239568b",
    "0",
    "0x79216912Bc403080f80a4c995f1163Df8239568b",
  ]);
  await maskie.waitForDeployment();
  console.log("Maskie deployed to:", maskie.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
