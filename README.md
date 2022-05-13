# Gachapon (WIP)

On-chain automated raffling system.

- Owner is able to create a new raffle by inserting ERC721's into the Gachapon
- Users are able to mint tickets as ERC721's by burning an underlying ERC20
- Owner reveals raffle by requesting Chainlink VRF
- Winning tickets are able to claim the prizes

This repo will move completely to foundry once `forge verify-contracts` works.

```ml
src
├── AuctionHouse.sol - "Auction Contract"
├── Gachapon.sol - "Raffling system"
├── Marketplace.sol - "Marketplace to allow purchases of limited off-chain items"
├── SoulboundTickets.sol - "ERC721 tickets that can be bought to enter a raffle; Soulbound"
├── Tickets.sol - "ERC721 tickets that can be bought to enter a raffle"
├── lib
│   ├── Choice.sol - "Library for returning an array of winners"
│   ├── Ownable.sol
│   └── interfaces.sol
└── test
    ├── ArrayUtils.sol
    ├── Gachapon.t.sol
    ├── TestDeploy.sol
    ├── WhitelistMarket.t.sol
    └── mocks
```

These contracts can be tried out at the [Mad Mouse Circus Slot-Machine](https://slot-machine.madmousecircus.io/).
Contracts:

- [Gachapon](https://etherscan.io/address/0x1cdbc6a0de7f74084156c6d02ff32e7e7d442465#code)
- [AuctionHouse](https://etherscan.io/address/0x6b805c98b5623b8100deb1d4a218ed1864e03836#code)
- [Marketplace](https://etherscan.io/address/0x6b363d51016e65feeb18b66d05f82e5d9715b0e8#code)
