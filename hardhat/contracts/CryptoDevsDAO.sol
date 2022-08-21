//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function purchase(uint256 tokenId) external payable;

    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);
}

interface ICryptoDevsNFT {
    // returns the number of NFT owned
    function balanceOf(address owner) external view returns (uint256);
    // returns the tokenId at a given index for owner
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256); 
}

contract CryptoDevsDAO is Ownable {
    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        // a mapping of CryptoDevs tokenIds to boolean indicating whether that NFT has been uased to cast a vote or not
        mapping (uint256 => bool) voters;
    }

    // a mapping of proposal id to Proposal
    mapping (uint256 => Proposal) public proposals;
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptodevsNFT;

    constructor (address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptodevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    modifier nftHolderOnly() {
        require(cryptodevsNFT.balanceOf(msg.sender) > 0, "Not a DAO member");
        _;
    }

    function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
        require(nftMarketplace.available(_nftTokenId), "NFT has been sold");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        numProposals++;

        return numProposals - 1;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(proposals[proposalIndex].deadline > block.timestamp, "Deadline exceeded");
        _;
    }

    enum Vote {
        YAY,
        NAY
    }

    function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];
        uint256 voterNFTBalance = cryptodevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        for(uint256 i = 0; i < voterNFTBalance; i++){
            uint256 tokenId = cryptodevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] == false){
                numVotes++;
                proposal.voters[tokenId] == true;
            }
        }
        require(numVotes > 0, "Already voted");

        if(vote == Vote.YAY){
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    modifier inactiveProposalOnly(uint256 proposalIndex){
        require(proposals[proposalIndex].deadline <= block.timestamp, "Deadline not exceeded");
        require(proposals[proposalIndex].executed == false, "Proposal already executed");
        _;
    }

    function executeProposal(uint256 proposalIndex) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        if(proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "Not enough funds");
            nftMarketplace.purchase{ value: nftPrice }(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}


}
