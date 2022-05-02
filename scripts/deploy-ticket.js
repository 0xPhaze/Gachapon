const { ethers } = require("hardhat");

// 0. hardcode addresses
// 1. deploy tickets implementation
// 2. set up tickets in gachapon
// 3. set mint/burn role in gouda for all contracts (Gachapon, Auctions, Market (burn only))
// 4. add links to website
// 5. link websites
// 6. transfer all ownership to vault??

async function main() {
  // const gachapon = await (await ethers.getContractFactory("Gachapon")).deploy();
  // const tickets = await (
  //   await ethers.getContractFactory("SoulboundTickets")
  // ).deploy("0x2802490CC40D0102846426D59Cf65677997D0398");
  const whitelistMarket = await (await ethers.getContractFactory("WhitelistMarket")).deploy();

  // console.log(`tickets: "${tickets.address}",`);
  console.log(`whitelistMarket: "${whitelistMarket.address}",`);
  // console.log(`auctionHouse: "${await deploy.auctionHouse()}",`);
  // console.log(`whitelistMarket: "${await deploy.whitelistMarket()}",`);

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