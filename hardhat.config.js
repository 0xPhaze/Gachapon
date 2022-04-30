require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
// require("hardhat-gas-reporter");
// require("hardhat-contract-sizer");
// require("solidity-coverage");
require("hardhat-contract-sizer");
require("dotenv").config();

const networks = ["mainnet", "rinkeby", "kovan", "polygon", "mumbai", "avalanche", "fuji", "bsc", "bsctest"];
const networkSettings = Object.assign(
  {},
  ...networks
    .map((network) => [network, process.env["PROVIDER_" + network.toUpperCase()]])
    .filter(([_, url]) => url !== undefined)
    .map(([network, url]) => ({
      [network]: {
        url: url,
        accounts: [process.env.PRIVATE_KEY],
      },
    }))
);

const argv = (key) => {
  const index = process.argv.indexOf(`--${key}`) + 1;
  return (
    process.argv.find((el) => el.startsWith(`--${key}=`))?.replace(`--${key}=`, "") || (index && process.argv[index])
  );
};

const networkName = argv("network");

const etherscanApiKey = ["mainnet", "rinkeby", "kovan"].includes(networkName)
  ? process.env.ETHERSCAN_KEY
  : ["bsc", "bscTest"].includes(networkName)
  ? process.env.BSCSCAN_KEY
  : ["avalanche", "fuji"].includes(networkName)
  ? process.env.SNOWTRACE_KEY
  : ["polygon", "mumbai"].includes(networkName)
  ? process.env.POLYGONSCAN_KEY
  : undefined;

const etherscanSettings = etherscanApiKey && {
  etherscan: {
    apiKey: etherscanApiKey,
  },
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 10000,
          },
        },
      },
    ],
  },
  networks: {
    ...networkSettings,
    hardhat: {
      // allowUnlimitedContractSize: true,
    },
  },
  mocha: {
    timeout: 0,
  },
  ...etherscanSettings,
  gasReporter: {
    enabled: true,
    currency: "USD",
    gasPrice: 100,
    coinmarketcap: "62e54920-2a0e-4644-a32b-59e48dc999ac",
  },
  paths: {
    sources: "./src",
  },
};
