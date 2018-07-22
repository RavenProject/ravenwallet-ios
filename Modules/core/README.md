New wallet creation:

If the native secure keystore is verified as being available, and it does not contain a master public key, then present the user with the option to create a new wallet.

Using a native source of entropy suitable for cryptographic use, obtain 128bits of random data.

Use BRBIP39Encode() to encode this 128bits of data as a 12 word recovery phrase.

Store the resulting recovery phrase in the native secure keystore.

Store any appropriate wallet authentication information in the secure keystore as well, such as a user selected passcode.

Use BIP39DeriveKey() to derive a master private key from the recovery phrase, feed this to BIP32MasterPubKey() to get the master pubkey, and store the master pubkey in the secure keystore.

Store the timestamp when the wallet was created in the secure keystore.

The creation time and master pubkey should be available to the wallet app without user authentication, so that it can be used for background network syncing, and/or syncing immediately on app launch prior to the user being authenticated. It's desirable to use the keystore so that it will be removed in any situation where the keystore data goes missing, such as a backup/restore to a different device that fails to migrate keystore data.

Existing wallet startup:

Retrieve the master pubkey and wallet creation time from the native secure keystore.

Create an array of BRTransaction structs from all transactions in the local data store.

Create a BRWallet struct with BRWalletNew(), using the master pubkey and transaction array.

Use BRWalletSetCallbacks() to setup callback functions to be notified of balance changes, and to add/update/remove transactions from the local data store.

Create arrays of BRPeer and BRMerkleBlock structs from peers and blocks in the local data store.

Create a BRPeerManager struct with BRPeerManagerNew() using the wallet struct, creation time, and arrays of peers and merkleblocks.

Use BRPeerManagerSetCallbacks() to setup callback functions to be notified of network syncing start/success/failure, of changes to transaction status (when a new block arrives), to store peers and blocks in the local data store, and a callback function for the peer manager to check the current status of the network connection.

Call BRPeerManagerConnect() to initiate connection and syncing with the bitcoin network.

Call BRPeerManagerSyncProgress() to monitor syncing progress.

Transaction creation and broadcast:

Call BRWalletCreateTransaction() with a payment address and amount.

Call BRWalletFeeForTx() to get the amount of the bitcoin network fee, and BRWalletAmountSentByTx()(no longer exists - simple search in the modules)_ for the final total, and present this information to the user along with anything else such as the payment address that the user needs to decide to authorize the transaction or not.

If the user chooses to authorize the transaction and successfully authenticates with passcode or fingerprint, retrieve the 12 word recovery phrase from the native secure keystore, and use BIP39DeriveKey() to derive a master private key (wallet seed) from the recovery phrase.

Call BRWalletSignTransaction() with the transaction and master private key (seed) to sign the transaction.

Call BRPeerManagerPublishTx() to broadcast the signed transaction to the bitcoin network.

Call BRPeerManagerRelayCount() with the transaction hash to monitor network propagation.