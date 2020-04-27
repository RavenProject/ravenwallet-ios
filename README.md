# RVN Wallet

This open source wallet is an [SPV wallet](https://en.bitcoinwiki.org/wiki/Simplified_Payment_Verification) for [Ravencoin](https://ravencoin.org) ([RVN](https://www.binance.us/en/trade/RVN_USD)).  It currently support Sending and Receiving RVN, Sending and receiving custom assets, asset creation, sending and receiving Restricted Assets, Sweeping addresses (RVN only).

### Building RVN Wallet
If you would like to build RVN Wallet yourself on a Mac, follow these instructions.
* Get XCode from Apple.
* Clone this repo.
* Open the workspace - ```Ravencoin.xcworkspace``` - (opening the project will not give you all the needed libraries)
* Choose RvnWallet and a target platform for simulator, use 'Generic iOS Device' for building for the store, or for your own iPhone connected via a cable.
* Choose Product->Run from the menu to build and run on simulator or connected iPhone

Note: To build your own for the app store requires permission from Apple, signing keys, and in our case phone calls with Apple lawyers, and Medici Ventures counsel for them to understand the source of the wallet and to trust us.

If you want to help improve the wallet, use the simulator or install on your own phone, you can do that with just the code available here.

Please do a pull request if you make meaningful improvements.  We love contributions from the Ravencoin community.

### Deployment (for Ravencoin core devs only)
* Steps as above.
* Increment version (Major if consensus adaptation, minor if new capabilities, sub-minor if spelling, etc.)
* Increment version on WatchKit to match.
* Choose 'Generic iOS Device' for the target
* Choose Product->Archive to build.
* Upload through [Apple's App Store platform](https://appstoreconnect.apple.com/).

