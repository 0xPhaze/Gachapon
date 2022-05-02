const { ethers } = require("hardhat");

async function main() {
  const genesis = await (await ethers.getContractFactory("MockMadMouse")).deploy();
  console.log(`genesis: "${genesis.address}",`);
  const troupe = await (await ethers.getContractFactory("MockMadMouse")).deploy();
  console.log(`troupe: "${troupe.address}",`);
  const gouda = await (await ethers.getContractFactory("MockGouda")).deploy();
  console.log(`gouda: "${gouda.address}",`);

  const market = await (
    await ethers.getContractFactory("WhitelistMarket")
  ).deploy(gouda.address, genesis.address, troupe.address);
  // .deploy();

  console.log(`whitelistMarket: "${market.address}",`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
