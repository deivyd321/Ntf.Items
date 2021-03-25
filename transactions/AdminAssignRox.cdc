import NonFungibleToken from 0xf8d6e0586b0a20c7
import RoxItems from 0xf8d6e0586b0a20c7

transaction(recipient: Address, typeID: UInt64) {
    
    let minter: &RoxItems.NFTMinter

    prepare(adminAcc: AuthAccount) {

        self.minter = adminAcc.borrow<&RoxItems.NFTMinter>(from: RoxItems.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        let recipient = getAccount(recipient)

        let receiver = recipient
            .getCapability(RoxItems.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

        self.minter.mintNFT(recipient: receiver, typeID: typeID)
    }
}