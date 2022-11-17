// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// Uncomment this line to use console.log
import "hardhat/console.sol";


contract MintPass_1155 is ERC1155,ReentrancyGuard, Ownable
{
    uint256 public maxMintAmountMintPass = 10000;
    uint256 public maxMintAmountFreePass = 50;
    uint256 private constant FREE_PASS = 1;
    uint256 private constant MINT_PASS = 2; 
    bool public paused = false; 
    uint256 counterMintPass = 0;
    uint256 counterFreePass = 0;

    address payable public immutable shareholderAddress;


    constructor(string memory base_uri,address payable shareholderAddress_) ERC1155(base_uri) {
        require(shareholderAddress_ != address(0));     
        shareholderAddress = shareholderAddress_;
    }

    function mint(uint256 tokenId,uint256 amount) external nonReentrant checkCounter_TypeMint(amount,tokenId)
    {
        require(!paused,"The function is paused for the moment");
        require(amount > 0,"The mint amount needs to be higher than zero");

        _mint(msg.sender, tokenId, amount, "");

        if(tokenId == FREE_PASS) {
            counterFreePass += amount;
        } 
        else if(tokenId == MINT_PASS) {
            counterMintPass += amount;
        }
    } 

    function mintInBatch(uint256[] memory tokenId,uint256[] memory amount) external onlyOwner nonReentrant checkCounter_TypeMintBatch(amount,tokenId)
    {
        require(!paused,"The function is paused for the moment");
     //   require(counter + amount <= maxMintAmountMintPass, "max amount reached");
        require(amount.length > 0,"The mint amount needs to be higher than zero");
        require(tokenId.length > 0,"The token id amount needs to be higher than zero");
        _mintBatch(msg.sender, tokenId, amount, "");
       // counter += amount;
    } 

    //Verificar segurança
    function burn(address packContract,address nftOwner,uint256 tokenId,uint256 amount) public
    {
        require(nftOwner != address(0),"address of nft owner must exist");
        require(msg.sender == packContract, "needs to be called by packContract");
        require(BalanceOfToken(nftOwner,tokenId) >= amount, "The account doesn't have that amout of tokens");

        _burn(nftOwner, tokenId, amount);
    }

   
    function TransferPass(address from, address to, uint256 tokenId, uint256 amount)  external onlyOwner nonReentrant
    {
        require(!paused,"The function is paused for the moment");
        require(from != address(0),"Need a valid address of owner");
        require(to != address(0),"Need a valid address to send");
        require(BalanceOfToken(from,tokenId) >= amount, "The account doesn't have that amout of tokens");
        require(amount > 0, "The amount needs to be higher than zero");

        safeTransferFrom(from,to,tokenId,amount,"");
    }

    //Verificar "ownability"
    function BalanceOfToken(address nftOwner, uint256 tokenId) public view returns(uint256) 
    {
       // require(msg.sender == nftOwner,"only token owner can check their balance their own token");
        return balanceOf(nftOwner,tokenId);
    }

    //Aux functions 
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner nonReentrant {
        require(!paused,"The function is paused for the moment");
        require(address(this).balance > 0, "Balance is 0");
        payable(shareholderAddress).transfer(address(this).balance);
    }

    //MODIFIERS
    modifier checkCounter_TypeMint(uint256 _mintAmount, uint256 tokenId) {
            require(_mintAmount > 0,"The mint amount needs to be higher than zero");

            if(tokenId == FREE_PASS) {
                require(counterFreePass + _mintAmount <= maxMintAmountFreePass, "The amount exceeds the available amount for free pass");
            }
            else if(tokenId == MINT_PASS){
                require(counterMintPass + _mintAmount <= maxMintAmountMintPass, "The amount exceeds the available amount for mint pass");
            }
            _;
    }

     modifier checkCounter_TypeMintBatch(uint256[] memory _mintAmount, uint256[] memory tokenId) {
            require(_mintAmount.length > 0,"The mint amount needs to be higher than zero");
            require(tokenId.length > 0,"The amount of tokens needs to be higher than zero");

            for(uint256 i = 0; i < tokenId.length;i++) 
            {
                if(tokenId[i] == FREE_PASS) {
                    require(counterFreePass + _mintAmount[i] <= maxMintAmountFreePass, "The amount exceeds the available amount for free pass");
                }
            else if(tokenId[i] == MINT_PASS){
                    require(counterMintPass + _mintAmount[i] <= maxMintAmountMintPass, "The amount exceeds the available amount for mint pass");
                }
            }
            _;
    }
}