const { ethers } = require("hardhat");

async function main() {
  const genesis = await (await ethers.getContractFactory("MockMadMouse")).deploy();
  console.log(`genesis: "${genesis.address}",`);
  const troupe = await (await ethers.getContractFactory("MockMadMouse")).deploy();
  console.log(`troupe: "${troupe.address}",`);
  // const deploy = await (await ethers.getContractFactory("TestDeployGachapon")).deploy(genesis.address, troupe.address);

  // const gachapon = await (await ethers.getContractFactory("G")).deploy();

  console.log(`gouda: "${await deploy.gouda()}",`);
  console.log(`gachapon: "${await deploy.gachapon()}",`);
  console.log(`auctionHouse: "${await deploy.auctionHouse()}",`);
  console.log(`whitelistMarket: "${await deploy.whitelistMarket()}",`);

  // const t = await (
  //   await ethers.getContractFactory("SoulboundTickets")
  // ).deploy("0x1cdbc6a0de7f74084156c6d02ff32e7e7d442465");
  // console.log(t.address);

  for (let i = 0; i < 10; i++)
    console.log(await ethers.provider.getStorageAt("0x10D3E8220C6c64ecA8e282fd03494f61B3F3896e", i));

  // console.log(`gouda: "${await deploy.gouda()}",`);

  // await deploy.initRaffles();
  // await deploy.initAuctions();

  // const Gachapon = await ethers.getContractFactory("Gachapon");
  // const gachapon = await Gachapon.deploy();

  // const MockERC20 = await ethers.getContractFactory("MockERC20");
  // const gouda = await MockERC20.deploy("Gouda", "GOOD");

  // const Tickets = await ethers.getContractFactory("Tickets");
  // const tickets = await Tickets.deploy(gachapon.address);

  // await gachapon.setGouda(gouda.address);
  // await gachapon.setTicketsImplementation(tickets.address);

  // const AuctionHouse = await ethers.getContractFactory("AuctionHouse");
  // const auctionHouse = await AuctionHouse.deploy(gouda.address);

  // const WhitelistMarket = await ethers.getContractFactory("WhitelistMarket");
  // const whitelistMarket = await WhitelistMarket.deploy(gouda.address);

  // console.log(`gouda: ${gouda.address}`);
  // console.log(`gachapon: ${gachapon.address}`);
  // console.log(`auctionHouse: ${auctionHouse.address}`);
  // console.log(`whitelistMarket: ${whitelistMarket.address}`);
  // unction createAuction(
  //   address toy,
  //   uint96 id,
  //   uint16 qualifierMaxEntrants,
  //   uint40 qualifierStart,
  //   uint16 qualifierChance,
  //   uint8 requirement,
  //   uint40 start,
  //   uint40 end
  // Mocks

  // const MockERC721 = await ethers.getContractFactory("MockERC721");

  // let mocks = [];
  // let ids = [];
  // let tx;

  // let names = ["Kaijus", "Godjiars", "Scrappy Squirrels", "Anonymice", "Red Pandas"];

  // for (let i = 0; i < 5; i++) {
  //   const mock = await MockERC721.deploy(names[i], "MERC721");

  //   mocks.push(mock.address);
  //   mocks.push(mock.address);
  //   mocks.push(mock.address);
  //   ids.push(i + 13);
  //   ids.push(i + 24);
  //   ids.push(i + 19);

  //   await mock.mint(owner.address, i + 13);
  //   await mock.mint(owner.address, i + 24);
  //   await mock.mint(owner.address, i + 19);

  //   tx = await mock.setApprovalForAll(gachapon.address, true);
  // }
  // await tx.wait();

  // const now = Math.floor(new Date().getTime() / 1000);
  // await gachapon.feedToys(
  //   mocks.slice(0, 3),
  //   ids.slice(0, 3),
  //   now - 1000,
  //   now - 100,
  //   1,
  //   ethers.utils.parseEther("10"),
  //   100
  // );
  // await gachapon.feedToys(mocks.slice(3, 7), ids.slice(3, 7), now, now + 600, 1, ethers.utils.parseEther("10"), 220);

  // await gachapon.feedToys(mocks.slice(12, 13), ids.slice(12, 13), now, now + 900, 1, ethers.utils.parseEther("8"), 300);

  // await gachapon.feedToys(
  //   mocks.slice(7, 10),
  //   ids.slice(7, 10),
  //   now + 10000,
  //   now + 40000,
  //   1,
  //   ethers.utils.parseEther("20"),
  //   200
  // );

  // await gachapon.feedToys(
  //   mocks.slice(10, 12),
  //   ids.slice(10, 12),
  //   now + 360000,
  //   now + 400000,
  //   1,
  //   ethers.utils.parseEther("13"),
  //   700
  // );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
