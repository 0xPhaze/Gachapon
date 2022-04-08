const { ethers } = require("hardhat");

async function main() {
  const Gachapon = await ethers.getContractFactory("Gachapon");
  const gachapon = await Gachapon.deploy();

  console.log("Gachapon deployed to:", gachapon.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
