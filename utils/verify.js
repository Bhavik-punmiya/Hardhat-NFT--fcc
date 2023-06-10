const { run , network} = require("hardhat")
const { storeImages } = require("./uploadToPinata")


const verify = (network.config.chainId == 31337) ?  async(contractAddress, args ) => {(console.log("You are on a local host "))}: async (contractAddress, args) => {

    console.log("Verifying contract...")
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        })
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log(` The Contract : ${contractAddress}  is Already verified!`)
        } else {
            console.log(e)
        }
    }
  }



module.exports = {
    verify,
}