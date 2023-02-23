## Painting Tokenizer Smart Contract

### Overview

Smart contract to tokenize assets, specifically paintings, listed on a it, with features such as listing paintings, making payments, minting NFTs, and transferring ownership to the buyer. Built using **Solidity** on [Remix](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=&cad=rja&uact=8&ved=2ahUKEwiz7uKP96v9AhWKed4KHTOkBVYQFnoECA4QAQ&url=https%3A%2F%2Fremix.ethereum.org%2F&usg=AOvVaw3PN4PhZQHRRyT3Djgq-u69) and deployed on **Goerli test network** for testing.

### Features

- Sellers can list their painting by providing necessary title,description and URI with whatever price they want. After listing they will recieve an ID called as listing ID which is associated with their painting. 

- A mint price is given which is the fee taken by the contract owner for minting and facilitating the transactions. This price also acts as the bottom limit for which the paintings can be listed.

- Sellers can remove their listing if it hasn't been bought by using their listing ID.

- Everyone can see each of the listings and the total number of listings.

- For buying, buyers need to pay the listing price as well as the minting price. Once the transaction is complete an NFT of the painting will be assigned to them.

- This contract uses openzeppelin's implementation of [ERC721](https://docs.openzeppelin.com/contracts/4.x/erc721) for minting NFTs and [ERC721URIStorage](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721URIStorage) for setting thier URI.

### Technical Skills

- Solidity
- Etherium
- Blockchain Technology
- Smart Contracts
- Non-Fungible Tokens(NFTs)


