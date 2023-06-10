const {network} = require("hardhat");
const {developmentChains, networkConfig} = require("../helper-hardhat-config")
const {verify} = require("../utils/verify")
const {storeImages,storeTokenUriMetadata} = require("../utils/uploadToPinata")
const imagesLocation = "./images/RandomNft"

const metadataTemplate = {
    name : "",
    description : "",
    image : "",
    attributes : [
        {
            trait_types :"Cutness",
            value: "100"
        }
    ]

}

module.exports = async function({getNamedAccounts, deployments}){
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let tokenUris = [
        'ipfs://QmfNZq8MHH81JHSsgj9z71V6DmGs52appX8rN92wPpeuPo',
        'ipfs://QmPdFBUecXZW1hrJZAn9uSYnnf68DdkJzMngmtS5z7Pask',
        'ipfs://QmPp9ZcASmSbufY3pvyZ4jj9afcXMECc7itki4fVjF36J2'
    ]

    if(process.env.UPLOAD_TO_PINATA == "true"){
        tokenUris = await handleTokenUris()
    }


    if(developmentChains.includes(network.name)){
        const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
        const tx = await vrfCoordinatorV2Mock.createSubscription()
        const txReceipt = await tx.wait(1)
        subscriptionId = txReceipt.events[0].args.subId
     }
     else{
        vrfCoordinatorV2Address = networkConfig[chainId].vrfCoordinatorV2
        subscriptionId = networkConfig[chainId].subscriptionId
     }
    
     log("------------------------------------------------------------------------------")
     arguments = [
        vrfCoordinatorV2Address,
        networkConfig[chainId]["gasLane"],
        networkConfig[chainId]["callbackGasLimit"],
        networkConfig[chainId]["mintFee"],
        subscriptionId,
        tokenUris,
    ]

    const randomipfsNft = await deploy("RandomIpfsNFt", {
        from : deployer,
        args : arguments,
        log : true,
        waitConfirmations : networkConfig.blockConfirmations || 1,

    })
    log("------------------------------------------------------------------------------")
    if(developmentChains.includes(network.name)  && process.env.ETHERSCAN_API_KEY){
        log("Verifying....")
        await verify(randomipfsNft.address, arguments)
    }

    log("---------------------------------------------")

}



async function handleTokenUris(){
    tokenUris = []
    const { responses : imageUploadResponses, files} = await storeImages(imagesLocation)

    for (imageUploadResponsesIndex in imageUploadResponses){
        let TokenUriMetadata = {...metadataTemplate}
    
        TokenUriMetadata.name = files[imageUploadResponsesIndex].replace("png", "")
        TokenUriMetadata.description = `Adorable ${TokenUriMetadata.name} pup`
        TokenUriMetadata.image = `ipfs://${imageUploadResponses[imageUploadResponsesIndex].IpfsHash}`
        console.log(`uploading ${TokenUriMetadata.name}....`)
        // store the json to pinata/ipfs
        const metadataUploadResponse = await storeTokenUriMetadata(TokenUriMetadata)
        tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`)

    }
    console.log("TokenUris Uploaded ! They are : ")
    console.log(tokenUris)

    return tokenUris

}

module.exports.tags = ["all", "randomipfs", "main"]