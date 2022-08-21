//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract FakeNFTMarketplace {
    mapping(uint256 => address) public tokens;
    
    uint256 nftPrice = 0.01 ether;

    // accept eth and marks the owner of the given tokenID as the caller
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.01 ether");
        tokens[_tokenId] = msg.sender;
    }

    // return the price of an NFT
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    // checks whether the tokenId has been sold or not
    function available(uint256 _tokenId) external view returns (bool) {
        if(tokens[_tokenId] == address(0)){
            return true;
        }
        return false;
    }
}