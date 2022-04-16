const { ethers } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();

  const Gachapon = await ethers.getContractFactory("Gachapon");
  const gachapon = await Gachapon.deploy();

  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const gouda = await MockERC20.deploy("Gouda", "GOOD");

  const Tickets = await ethers.getContractFactory("Tickets");
  const tickets = await Tickets.deploy(gachapon.address);

  await gachapon.setGouda(gouda.address);
  await gachapon.setTicketsImplementation(tickets.address);

  console.log("Gachapon deployed to:", gachapon.address);
  console.log("Gouda deployed to:", gouda.address);
  // ? "ipfs://QmcU3dhpgV9uWwgWQ7aPCsyZSYZDZMCKj1FrDJCEQAceoP/winning-ticket.json"
  // : "ipfs://QmcU3dhpgV9uWwgWQ7aPCsyZSYZDZMCKj1FrDJCEQAceoP/raffle-ticket.json";

  const MockERC721 = await ethers.getContractFactory("MockERC721");

  let mocks = [];
  let ids = [];
  let tx;

  let names = ["Kaijus", "Godjiars", "Scrappy Squirrels", "Anonymice", "Red Pandas"];

  for (let i = 0; i < 5; i++) {
    const mock = await MockERC721.deploy(names[i], "MERC721");

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
  await gachapon.feedToys(
    mocks.slice(0, 3),
    ids.slice(0, 3),
    now - 1000,
    now - 100,
    1,
    ethers.utils.parseEther("10"),
    100
  );
  await gachapon.feedToys(mocks.slice(3, 7), ids.slice(3, 7), now, now + 3600, 1, ethers.utils.parseEther("10"), 220);

  await gachapon.feedToys(
    mocks.slice(12, 13),
    ids.slice(12, 13),
    now,
    now + 142000,
    1,
    ethers.utils.parseEther("8"),
    300
  );
  await gachapon.feedToys(
    mocks.slice(7, 10),
    ids.slice(7, 10),
    now + 10000,
    now + 40000,
    1,
    ethers.utils.parseEther("20"),
    200
  );

  await gachapon.feedToys(
    mocks.slice(10, 12),
    ids.slice(10, 12),
    now + 360000,
    now + 400000,
    1,
    ethers.utils.parseEther("13"),
    700
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
