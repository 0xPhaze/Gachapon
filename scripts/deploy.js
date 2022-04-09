const { ethers } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();

  const Gachapon = await ethers.getContractFactory("Gachapon");
  const gachapon = await Gachapon.deploy();

  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const gouda = await MockERC20.deploy("", "", 18);

  const Tickets = await ethers.getContractFactory("Tickets");
  const tickets = await Tickets.deploy(gachapon.address);

  await gachapon.setGouda(gouda.address);
  await gachapon.setTicketsImplementation(tickets.address);

  console.log("Gachapon deployed to:", gachapon.address);
  console.log("Gouda deployed to:", gouda.address);

  const MockERC721 = await ethers.getContractFactory("MockERC721");

  let mocks = [];
  let ids = [];
  let tx;
  for (let i = 0; i < 5; i++) {
    const mock = await MockERC721.deploy("MockERC721", "MERC721");

    mocks.push(mock.address);
    mocks.push(mock.address);
    mocks.push(mock.address);
    ids.push(i + 13);
    ids.push(i + 24);
    ids.push(i + 19);

    await mock.mint(owner.address, i + 13);
    await mock.mint(owner.address, i + 24);
    await mock.mint(owner.address, i + 19);

    tx = await mock.setApprovalForAll(gachapon.address, true);
  }
  await tx.wait();

  const now = Math.floor(new Date().getTime() / 1000);
  await gachapon.feedToys(mocks, ids, now - 1000, now - 100, ethers.utils.parseEther("10"), 100);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
