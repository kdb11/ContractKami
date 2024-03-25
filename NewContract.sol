// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
 
contract NFTMarketplace is ERC721 {
    struct Transaction {
        uint256 chainId;
        string txHash;
        string email;
        string addressFrom;
        string addressTo;
        uint256 amount;
        uint256 timestamp;
        string contractAddress;
        string tokenId;
    }
 
    struct NftAsset {
        uint256 chainId;
        string contractAddress;
        string tokenId;
        string metadata;
        string name;
        string mediaUrl;
        string mediaType;
        string mediaFormat;
        string ownerAddress;
        string ownerEmail;
        string status;
        uint256 rentalExpiration;
    }
 
    mapping(uint256 => Transaction) public transactions;
    mapping(bytes32 => NftAsset) public nftAssets;

    function getRentalExpiration(uint256 chainId, string memory tokenId) external view returns (uint256) {
        bytes32 assetId = keccak256(abi.encodePacked(chainId, msg.sender, tokenId));
        return nftAssets[assetId].rentalExpiration;
    }
 
    event TransactionAdded(uint256 indexed chainId, string indexed txHash);
    event NftAssetAdded(uint256 indexed chainId, string indexed contractAddress, string indexed tokenId);
 
    //Oklart namn?
    constructor() ERC721("Kami", "NAMO") {}
 
    function addTransaction(
        uint256 chainId,
        string memory txHash,
        string memory email,
        string memory addressFrom,
        string memory addressTo,
        uint256 amount,
        string memory contractAddress,
        string memory tokenId
    ) external {
        transactions[chainId] = Transaction(chainId, txHash, email, addressFrom, addressTo, amount, block.timestamp, contractAddress, tokenId);
        emit TransactionAdded(chainId, txHash);
    }
 
    function addNftAsset(
        uint256 chainId,
        string memory contractAddress,
        string memory tokenId,
        string memory metadata,
        string memory name,
        string memory mediaUrl,
        string memory mediaType,
        string memory mediaFormat,
        string memory ownerAddress,
        string memory ownerEmail,
        string memory status
    ) external {
        bytes32 assetId = keccak256(abi.encodePacked(chainId, contractAddress, tokenId));
        nftAssets[assetId] = NftAsset(chainId, contractAddress, tokenId, metadata, name, mediaUrl, mediaType, mediaFormat, ownerAddress, ownerEmail, status, block.timestamp);
        emit NftAssetAdded(chainId, contractAddress, tokenId);
    }
 
    function getTransaction(uint256 chainId, string calldata txHash) external view returns (
        string memory email,
        string memory addressFrom,
        string memory addressTo,
        uint256 amount,
        uint256 timestamp,
        string memory contractAddress,
        string memory tokenId
    ) {
        Transaction memory transaction = transactions[chainId];
        return (
            transaction.email,
            transaction.addressFrom,
            transaction.addressTo,
            transaction.amount,
            transaction.timestamp,
            transaction.contractAddress,
            transaction.tokenId
        );
    }
 
    function getNftAsset(uint256 chainId, string calldata contractAddress, string calldata tokenId) external view returns (
        string memory metadata,
        string memory name,
        string memory mediaUrl,
        string memory mediaType,
        string memory mediaFormat,
        string memory ownerAddress,
        string memory ownerEmail,
        string memory status
    ) {
        bytes32 assetId = keccak256(abi.encodePacked(chainId, contractAddress, tokenId));
        NftAsset memory nftAsset = nftAssets[assetId];
        return (
            nftAsset.metadata,
            nftAsset.name,
            nftAsset.mediaUrl,
            nftAsset.mediaType,
            nftAsset.mediaFormat,
            nftAsset.ownerAddress,
            nftAsset.ownerEmail,
            nftAsset.status
            
        );
    }
 
    function listForSale(uint256 chainId, string memory tokenId) external {
        bytes32 assetId = keccak256(abi.encodePacked(chainId, msg.sender, tokenId));
        require(bytes(nftAssets[assetId].status).length == 0 || keccak256(bytes(nftAssets[assetId].status)) == keccak256("Rented"), "NFT is already listed for sale or rent");
        nftAssets[assetId].status = "ForSale";
    }
 
    function buyNFT(uint256 chainId, string memory tokenId) external payable {
        bytes32 assetId = keccak256(abi.encodePacked(chainId, msg.sender, tokenId));
        require(keccak256(bytes(nftAssets[assetId].status)) == keccak256("ForSale"), "NFT is not for sale");
        address payable seller = payable(ownerOfAsset(chainId, tokenId));
        address payable buyer = payable(msg.sender);
        uint256 price = msg.value;
        uint256 salePrice = 100; // Example sale price, you can set your desired price here
        require(price >= salePrice, "Insufficient payment");

        // Convert tokenId to uint256
        uint256 tokenIdUint = uint256(keccak256(abi.encodePacked(tokenId)));

        // Transfer NFT ownership
        _transfer(seller, buyer, tokenIdUint);

        // Update NFT status
        nftAssets[assetId].status = "Sold";

        // Transfer payment to seller
        seller.transfer(price);

        // Emit event
        emit TransactionAdded(chainId, ""); // Add relevant transaction hash if available
    }

 
    function rentNFT(uint256 chainId, string memory tokenId, uint256 duration) external payable {
    bytes32 assetId = keccak256(abi.encodePacked(chainId, msg.sender, tokenId));
    require(keccak256(bytes(nftAssets[assetId].status)) == keccak256("ForRent"), "NFT is not for rent");
    address payable owner = payable(ownerOfAsset(chainId, tokenId));
    address payable renter = payable(msg.sender);
    uint256 price = msg.value;
    uint256 rentPrice = 50; // Example rent price, you can set your desired price here
    require(price >= rentPrice, "Insufficient payment");

    // Convert tokenId to uint256
    uint256 tokenIdUint = uint256(keccak256(abi.encodePacked(tokenId)));

    // Transfer NFT ownership
    _transfer(owner, renter, tokenIdUint);

    // Update NFT status
    nftAssets[assetId].status = "Rented";

    // Set rental expiration
    nftAssets[assetId].rentalExpiration = block.timestamp + duration;

    // Transfer payment to owner
    owner.transfer(price);

    // Emit event
    emit TransactionAdded(chainId, ""); // Add relevant transaction hash if available
}

 
    function ownerOfAsset(uint256 chainId, string memory tokenId) private view returns (address) {
        bytes32 assetId = keccak256(abi.encodePacked(chainId, msg.sender, tokenId));
        address owner = ownerOf(uint256(keccak256(abi.encodePacked(chainId, tokenId))));
        require(owner != address(0), "Invalid owner address");
        return owner;
    }
}