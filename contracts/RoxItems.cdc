import NonFungibleToken from "NonFungibleToken.cdc"

// RoxItems
// NFT items for Rox!
//
pub contract RoxItems: NonFungibleToken {

    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, collectibleId: String)

    // Named Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // The total number of RoxItems that have been minted
    pub var totalSupply: UInt64

    // NFT
    // A Rox Item as an NFT
    pub resource NFT: NonFungibleToken.INFT {
        // The token's ID
        pub let id: UInt64
        pub let tier: String // enum in BE
        pub let collectibleId: String
        pub let mintNumber: UInt64 // Don't know what it is

        init(initID: UInt64, collectibleId: String, tier: String, mintNumber: UInt64) {
            self.id = initID
            self.collectibleId = collectibleId
            self.tier = tier
            self.mintNumber = mintNumber
        }
    }

    pub resource interface RoxItemsCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowRoxItem(id: UInt64): &RoxItems.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow RoxItem reference: The ID of the returned reference is incorrect"
            }
        }
    }


    pub resource CollectionPrivate: RoxItemsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {

        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @RoxItems.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowRoxItem
        // Gets a reference to an NFT in the collection as a RoxItem,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the RoxItem.
        pub fun borrowRoxItem(id: UInt64): &RoxItems.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &RoxItems.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        init () {
            self.ownedNFTs <- {}
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.CollectionPrivate {
        return <- create CollectionPrivate()
    }

	pub resource NFTMinter {

		pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, collectibleId: String, tier: String, mintNumber : UInt64) {

            emit Minted(id: RoxItems.totalSupply, collectibleId: collectibleId)

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-create RoxItems.NFT(initID: RoxItems.totalSupply, collectibleId: collectibleId, tier: tier, mintNumber: mintNumber))

            RoxItems.totalSupply = RoxItems.totalSupply + (1 as UInt64)
		}
	}

    // fetch
    // Get a reference to a RoxItem from an account's Collection, if available.
    // If an account does not have a RoxItems.Collection, panic.
    // If it has a collection but does not contain the itemId, return nil.
    // If it has a collection and that collection contains the itemId, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &RoxItems.NFT? {
        let collection = getAccount(from)
            .getCapability(RoxItems.CollectionPublicPath)
            .borrow<&RoxItems.CollectionPrivate{RoxItems.RoxItemsCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust RoxItems.Collection.borowRoxItem to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowRoxItem(id: itemID)
    }

    // initializer
    //
	init() {
        self.CollectionStoragePath = /storage/RoxItemsCollection
        self.CollectionPublicPath = /public/RoxItemsCollection
        self.MinterStoragePath = /storage/RoxItemsMinter

        self.totalSupply = 0

        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
	}
}