//
//  Sender.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-01-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class AddressBookManager {
    
    let db: CoreDatabase = CoreDatabase()
    
    func loadAddress(callBack: @escaping ([AddressBook]) -> Void) {
        db.loadAddressBook { addresses in
            callBack(addresses)
        }
    }
    
    func isAddressExiste(address:String, callback: @escaping (Bool) -> Void) {
        db.isAddressBookExiste(address: address) { (addressBook, isExiste) in
            callback(isExiste)
        }
    }
    
    func addAddressBook(newAddress:AddressBook, successCallBack: @escaping () -> Void, faillerCallBack: @escaping () -> Void) {
        db.addressBookAdded(newAddress, callback: { isAdded in
            if(isAdded)
            {
                successCallBack()
            }
            else{
                faillerCallBack()
            }
        })
    }
    
    func updateAddressBook(newAddress:AddressBook, oldAddress:String, successCallBack: @escaping () -> Void, faillerCallBack: @escaping () -> Void) {
        db.updateAddressBook(newAddress, where: oldAddress, callback: { isUpdated in
            if(isUpdated)
            {
                successCallBack()
            }
            else{
                faillerCallBack()
            }
        })
    }
    
    func deleteAddressBook(address:String, successCallBack: @escaping () -> Void, faillerCallBack: @escaping () -> Void) {
        db.deleteAddressBook(address, callback: { isDeleted in
            if(isDeleted)
            {
                successCallBack()
            }
            else{
                faillerCallBack()
            }
        })
    }



}
