const { ethers } = require("hardhat");

async function main() {
  const genesis = await (await ethers.getContractFactory("MockMadMouse")).deploy();
  console.log(`genesis: "${genesis.address}",`);
  const troupe = await (await ethers.getContractFactory("MockMadMouse")).deploy();
  console.log(`troupe: "${troupe.address}",`);
  const gouda = await (await ethers.getContractFactory("MockGouda")).deploy();
  console.log(`gouda: "${gouda.address}",`);

  const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
  const auctions = await AuctionHouse.deploy(gouda.address, genesis.address, troupe.address);

  const Market = await ethers.getContractFactory("Marketplace");
  const market = await Market.deploy(gouda.address, genesis.address, troupe.address);

  const Gachapon = await ethers.getContractFactory("Gachapon");
  const gachapon = await Gachapon.deploy(gouda.address, genesis.address, troupe.address);

  console.log(`marketplace: "${market.address}",`);
  console.log(`auctionHouse: "${auctions.address}",`);
  console.log(`gachapon: "${gachapon.address}",`);

  await gachapon.deployed();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
