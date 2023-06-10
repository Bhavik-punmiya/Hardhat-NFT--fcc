// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// imports
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract RandomIpfsNFt is ERC721URIStorage, VRFConsumerBaseV2 ,Ownable{
    
    error  RandomIpfsNft__AlreadyInitialized();
    error RandomIpfsNFt__RangeOutOfBound();
    error RandomIpfsNft__NeedMoreETHSent();
    error RandomIpfsNFt__TransferFailed();

    enum Breed {
        PUG, 
        SHIBA_INU,
        ST_BERNAD
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint16 private immutable i_callbackGasLimit;
    uint256 private immutable i_mintfee;
    uint64 private immutable i_subscriptionId;
     uint32 private constant NUM_WORDS=1;
     uint16 private constant REQUEST_CONFIRMATIONS=3;
    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;

    // NFT Variables 
    uint256 public s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenURI;
     bool private s_initialized;
    //Events 
    event NftReqeuested(uint256 indexed requestId , address requester);
    event NftMinted(Breed dogBreed, address minter);

    constructor(
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint16 callbackGasLimit,
        uint256 mintFee,
        uint64 subscriptionId,
        string[3] memory dogTokenUris
        ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("Random IPFS NFT", "RIN"){
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_mintfee = mintFee;
        i_subscriptionId = subscriptionId;
        _initializeContract(dogTokenUris);
        s_tokenCounter = 0;
    }

    function requrestNft() public payable  returns (uint256 requestId){
        if(msg.value < i_mintfee){
            revert RandomIpfsNft__NeedMoreETHSent();
        }

        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            i_callbackGasLimit,
            REQUEST_CONFIRMATIONS,
            NUM_WORDS
        );
    s_requestIdToSender[requestId] = msg.sender;
    emit NftReqeuested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomwords) internal override{
        
        address dogOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;
        _safeMint(dogOwner, newTokenId);
        uint256 moddedRng = randomwords[0] % MAX_CHANCE_VALUE; 
        Breed dogBreed  = getBreedFromModdedRng(moddedRng);
        _safeMint(dogOwner, newTokenId);
        _setTokenURI(newTokenId, s_dogTokenURI[uint256(dogBreed)]);
        emit NftMinted(dogBreed , dogOwner);
    }
    function getBreedFromModdedRng(uint256 moddedRng) public pure returns (Breed){
        uint256 cumulativeSum = 0;
        uint256[3] memory chanceArray = getChanceArray();
        for(uint256 i=0;i<chanceArray.length;i++){
            if(moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]){
                return Breed(i); 
            }
            cumulativeSum += chanceArray[i];
        }
        revert RandomIpfsNFt__RangeOutOfBound();
    }
     function _initializeContract(string[3] memory dogTokenUris) private {
        if (s_initialized) {
            revert RandomIpfsNft__AlreadyInitialized();
        }
        s_dogTokenURI = dogTokenUris;
        s_initialized = true;
    }
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success , ) = payable(msg.sender).call{ value : amount}("");
        if(!success) {revert RandomIpfsNFt__TransferFailed();}
    }

    function getChanceArray() public pure returns (uint256[3] memory){
        return [10, 30 ,MAX_CHANCE_VALUE];
    }

    function getMintFee() public view returns(uint256){
        return i_mintfee;
    }

    function getDogTokenUris(uint256 index) public view returns (string[] memory){
        return s_dogTokenURI;
    }
    function getTokenCounter() public view returns (uint256){
        return s_tokenCounter;
    }
}