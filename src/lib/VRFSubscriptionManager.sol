// SPDX-License-Identifier: MIT
// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "./Ownable.sol";

abstract contract VRFSubscriptionManager is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    bytes32 private keyHash;
    uint64 private subscriptionId;
    uint32 private callbackGasLimit = 100000;

    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(linkToken);
        keyHash = keyHash_;

        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    /* ------------- Internal ------------- */

    function requestRandomWords() internal returns (uint256) {
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                subscriptionId,
                3,
                callbackGasLimit,
                1
            );
    }

    // /* ------------- Owner ------------- */

    // function setVRFParameters(uint32 callbackGasLimit_, bytes32 keyHash_) external onlyOwner {
    //     callbackGasLimit = callbackGasLimit_;
    //     keyHash = keyHash_;
    // }

    // function topUpSubscription(uint256 amount) external onlyOwner {
    //     LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(subscriptionId));
    // }
}

abstract contract VRFSubscriptionManagerMainnet is VRFSubscriptionManager {
    constructor()
        VRFSubscriptionManager(
            0x6168499c0cFfCaCD319c818142124B7A15E857ab,
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709,
            0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
        )
    {}
}

abstract contract VRFSubscriptionManagerMock {
    uint256 public requestId = 13949503;

    function requestRandomWords() internal returns (uint256) {
        return requestId++;
    }

    function forceFulfillRandomWords(uint256 id) external {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = uint256(keccak256(abi.encode(id)));
        fulfillRandomWords(id, randomWords);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;
}
