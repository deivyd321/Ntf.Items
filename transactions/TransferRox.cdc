import NonFungibleToken from 0xf8d6e0586b0a20c7
import RoxItems from 0xf8d6e0586b0a20c7

transaction(recipient: Address, withdrawID: UInt64) {

    let tempNFT: @NonFungibleToken.NFT

    prepare(signer: AuthAccount) {

        let collectionRef = signer.borrow<&RoxItems.CollectionPrivate>(from: RoxItems.CollectionStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")

        self.tempNFT <- collectionRef.withdraw(withdrawID: withdrawID)
    }
    execute {

        let recipient = getAccount(recipient)

        let depositRef = recipient.getCapability(RoxItems.CollectionPublicPath)!.borrow<&{NonFungibleToken.CollectionPublic}>()!

        depositRef.deposit(token: <- self.tempNFT)

        log("NFT Transferred")
  }
}
