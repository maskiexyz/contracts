import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-verify";

const PRIVATE_KEY = "";

const config: HardhatUserConfig = {
  networks: {
    baseGoerli: {
      url: "https://goerli.base.org",
      accounts: [`0x${PRIVATE_KEY}`],
      gasPrice: 1000000000,
    },
  },
  etherscan: {
    apiKey: {
      "base-goerli": "PLACEHOLDER_STRING",
    },
    customChains: [
      {
        network: "base-goerli",
        chainId: 84531,
        urls: {
          apiURL: "https://api-goerli.basescan.org/api",
          browserURL: "https://goerli.basescan.org",
        },
      },
    ],
  },
  solidity: "0.8.19",
};

export default config;
