// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./Mint_Free_Pass_1155.sol";

import "hardhat/console.sol";

//Question
//Is there max limit of packs for each sale type? how much?
//Which contracts should have the upgradable pattern
//Check the pre sale and public sale variables
//How many pre sales and prices
contract PackMint is ERC1155, ReentrancyGuard, Ownable {

        bool public paused = false;
        address payable public immutable shareholderAddress;

        uint256 public constant MAX_SUPPLY_PACKS = 10000;
        uint256 public publicCost = 0.1 ether;
        uint256 public presaleCost = 0.05 ether;
        uint256 public counterMints = 0;
        MintPass_1155 passContract;
        address mint_free_pass;

        //Are we going to have different sales stages
        bool public presaleActive = false;
        bool public publicActive = false;


        constructor(string memory base_uri,address payable shareholderAddress_) ERC1155(base_uri)
        {
            require(shareholderAddress_ != address(0));   
            shareholderAddress = shareholderAddress_;
        }

        function UpdateContractAddress_MintPass(address contractAddress) public onlyOwner {
            mint_free_pass = contractAddress;
            passContract = MintPass_1155(contractAddress);
        }

        function PublicMint(uint256 _mintAmount, uint256 tokenId) external payable nonReentrant mint_check_conditions(_mintAmount){
            require(publicActive, "Public sale didn't start yet");
            require(msg.value >= priceMint() * _mintAmount, "Insufficient funds!");
            MintLoop(msg.sender, tokenId,_mintAmount);          
        }

        function MintPassMint(uint256 _mintAmount, uint256 tokenId) external payable nonReentrant mint_check_conditions(_mintAmount) mint_by_pass(_mintAmount,tokenId){
            require(presaleActive, "Private sale didn't start yet");
            require(msg.value >= priceMint() * _mintAmount, "Insufficient funds!");
            MintLoop(msg.sender,0,_mintAmount);
             passContract.burn(address(this),msg.sender, tokenId, _mintAmount);
        }

        function FreePassMint(uint256 _mintAmount, uint256 tokenId) public nonReentrant mint_check_conditions(_mintAmount) mint_by_pass(_mintAmount,tokenId){
            require(presaleActive, "Private sale didn't start yet");
            MintLoop(msg.sender,0,_mintAmount);

            passContract.burn(address(this),msg.sender, tokenId, _mintAmount);

        }
        function PrivateMint(uint256 _mintAmount,uint256 tokenId) external onlyOwner nonReentrant mint_check_conditions(_mintAmount){
            MintLoop(msg.sender,tokenId,_mintAmount);
        }

        function MintLoop(address to,uint256 tokenId,uint256 _mintAmount) internal  {
            _mint(to, tokenId,_mintAmount, "");

            unchecked {
                counterMints += _mintAmount;
            }
        }
        //Verificar segurança
        function Burn(address nftOwner, uint256 tokenId, uint256 amount) external {
            require(nftOwner != address(0),"address of nft owner must exist");
 //           require(msg.sender == nftOwner,"only token owner can burn their own token");
            _burn(nftOwner, tokenId, amount);
        }


        function pause(bool _state) external onlyOwner {
            paused = _state;
        }

        function setPreSale(bool _state) external onlyOwner {
            presaleActive = _state;
        }

        function setPublicSale(bool _state) external onlyOwner {
            publicActive = _state;
        }

        function BalanceOfToken(address nftOwner, uint256 tokenId) public view returns(uint256) {
            //require(msg.sender == nftOwner,"only token owner can check their balance their own token");
            return balanceOf(nftOwner,tokenId);
        }

        function priceMint() internal view returns(uint256) {
            if(presaleActive) return presaleCost;

            return publicCost;
        }

        
        function withdraw() external onlyOwner nonReentrant {
            require(address(this).balance > 0, "Balance is 0");
            payable(shareholderAddress).transfer(address(this).balance);
        }

        //Modifiers
        modifier mint_check_conditions(uint256 _mintAmount) {
            require(!paused, "The contract is paused!");
            require(_mintAmount > 0,"The mint amount needs to be higher than zero");
            require(counterMints + _mintAmount <= MAX_SUPPLY_PACKS, "The amount exceeds the available amount");
            _;
        }

        modifier mint_by_pass(uint256 _mintAmount, uint256 typeOfPass) {
            uint256 amountMintPass = passContract.BalanceOfToken(msg.sender,typeOfPass);
            require(amountMintPass > 0,"The amount of mint pass need to be greater than 0");
            require(amountMintPass >= _mintAmount,"The mint amount required needs to be equal or lower to the total amount of mint passes existed");
            _;
        }

        
}