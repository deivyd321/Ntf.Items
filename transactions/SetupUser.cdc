import NonFungibleToken from 0xf8d6e0586b0a20c7
import RoxItems from 0xf8d6e0586b0a20c7

transaction {
    prepare(signer: AuthAccount) {
      // if the account doesn't already have a collection
      if signer.borrow<&RoxItems.CollectionPrivate>(from: RoxItems.CollectionStoragePath) == nil {

        // create a new empty collection
        let collection <- RoxItems.createEmptyCollection()
            
        // save it to the account
        signer.save(<-collection, to: RoxItems.CollectionStoragePath)

        // create a public capability for the collection
        signer.link<&RoxItems.CollectionPrivate{NonFungibleToken.CollectionPublic, RoxItems.RoxItemsCollectionPublic}>(RoxItems.CollectionPublicPath, target: RoxItems.CollectionStoragePath)
        
        log("Completed setup for account:")
        log(signer.address)
      }
      else{
        log("Signer has completed set up before")
      }
    }
}
