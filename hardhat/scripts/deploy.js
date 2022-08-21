const { ethers } = require("hardhat");
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require("../constants");

async function main (){
  const FakeNFTMarketPlace = await ethers.getContractFactory("FakeNFTMarketplace");
  const fakeNFTMarketPlace = await FakeNFTMarketPlace.deploy();
  await fakeNFTMarketPlace.deployed();

  console.log("FakeNFTMarketplace deployed to : ", fakeNFTMarketPlace.address);

  const CryptoDevsDAO = await ethers.getContractFactory("CryptoDevsDAO");
  const cryptoDevsDAO = await CryptoDevsDAO.deploy(
    fakeNFTMarketPlace.address,
    CRYPTODEVS_NFT_CONTRACT_ADDRESS,
    {
      value: ethers.utils.parseEther("0.3"),
    }
  );
  await cryptoDevsDAO.deployed();

  console.log("CryptoDevsDAO deployed to: ", cryptoDevsDAO.address);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })