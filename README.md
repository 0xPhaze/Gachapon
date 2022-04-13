# Gachapon (WIP)

On-chain automated raffling system.

- Owner is able to create a new raffle by inserting ERC721's into the Gachapon
- Users are able to mint tickets as ERC721's by burning an underlying ERC20
- Owner reveals raffle by requesting Chainlink VRF
- Winning tickets are able to claim the prizes

This repo will move completely to foundry once `forge verify-contracts` works.

```ml
src
├── Gachapon.sol - "Raffling system"
├── Tickets - "ERC721 tickets that can be bought to enter a raffle"
├── WhitelistMarket.sol - "Will be removed"
├── lib
│   ├── Choice.sol - "Library for returning an array of winners"
│   ├── Gouda.sol
│   ├── Ownable.sol
│   ├── VRFSubscriptionManager.sol - "Wrapper for chainlinks VRFv2"
│   └── interfaces.sol
└── test
    ├── Choice.t.sol
    ├── Gachapon.t.sol
    └── WhitelistMarket.t.sol
```
