// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

interface CustomIERC721 {
        function safeMint(address to) external;

        function currentTokenId() external view returns(uint256);
}

