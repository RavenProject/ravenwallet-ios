//
//  Sender.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-01-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation
import Core

enum AssetType {//BMEX
    case UNIQUE
    case CHANNEL
    case OWNER
    case ROOT
    case SUB
    case INVALID
}

let MAX_NAME_LENGTH = 30;
let MAX_IPFSHASH_LENGTH = 46;

let ROOT_NAME_CHARACTERS = try? NSRegularExpression(pattern: "^[A-Z0-9._]{3,}$", options: [])
let SUB_NAME_CHARACTERS = try? NSRegularExpression(pattern: "^[A-Z0-9._]+$", options: [])
let UNIQUE_TAG_CHARACTERS = try? NSRegularExpression(pattern: "^[-A-Za-z0-9@$%&*()\\{}_.?:]+$", options: [])
let CHANNEL_TAG_CHARACTERS = try? NSRegularExpression(pattern: "^[A-Z0-9._]+$", options: [])

let DOUBLE_PUNCTUATION = try? NSRegularExpression(pattern: "^.*[._]{2,}.*$", options: [])
let LEADING_PUNCTUATION = try? NSRegularExpression(pattern: "^[._].*$", options: [])
let TRAILING_PUNCTUATION = try? NSRegularExpression(pattern: "^.*[._]$", options: [])

let SUB_NAME_DELIMITER = try? NSRegularExpression(pattern: "/", options: [])
let UNIQUE_TAG_DELIMITER = try? NSRegularExpression(pattern: "#", options: [])
let CHANNEL_TAG_DELIMITER = try? NSRegularExpression(pattern: "~", options: [])

let UNIQUE_INDICATOR = try? NSRegularExpression(pattern: "^[^#]+#[^#]+$", options: [])
let CHANNEL_INDICATOR = try? NSRegularExpression(pattern: "^[^~]+~[^~]+$", options: [])
let OWNER_INDICATOR = try? NSRegularExpression(pattern: "^[^!]+!$", options: [])

let RAVEN_NAMES = try? NSRegularExpression(pattern: "^RVN|^RAVEN|^RAVENCOIN|^RAVENC0IN|^RAVENCO1N|^RAVENC01N", options: [])


let IPFSHASH = try? NSRegularExpression(pattern: "^[^!]+!$", options: [])
let IPFSHASH_START = try? NSRegularExpression(pattern: "^Qm", options: [])

class AssetValidator {
    
    static let shared = AssetValidator()
    
    func isRootNameValid(name:String) -> Bool {
        let res1 = ROOT_NAME_CHARACTERS?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let res2 = DOUBLE_PUNCTUATION?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let res3 = LEADING_PUNCTUATION?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let res4 = TRAILING_PUNCTUATION?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let res5 = RAVEN_NAMES?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let result = res1 && !res2 && !res3 && !res4 && !res5
        return result
    }
    
    func IsSubNameValid(name:String) -> Bool {
        let res1 = SUB_NAME_CHARACTERS?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let res2 = DOUBLE_PUNCTUATION?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let res3 = LEADING_PUNCTUATION?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let res4 = TRAILING_PUNCTUATION?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        let result = res1 && !res2 && !res3 && !res4
        return result
    }
    
    func IsUniqueTagValid(tag:String) -> Bool {
        let result = UNIQUE_TAG_CHARACTERS?.firstMatch(in: tag, options: [], range: NSRange(location: 0, length: tag.count)) != nil
        return result
    }
    
    func IsChannelTagValid(tag:String) -> Bool {
        let res1 = CHANNEL_TAG_CHARACTERS?.firstMatch(in: tag, options: [], range: NSRange(location: 0, length: tag.count)) != nil
        let res2 = DOUBLE_PUNCTUATION?.firstMatch(in: tag, options: [], range: NSRange(location: 0, length: tag.count)) != nil
        let res3 = LEADING_PUNCTUATION?.firstMatch(in: tag, options: [], range: NSRange(location: 0, length: tag.count)) != nil
        let res4 = TRAILING_PUNCTUATION?.firstMatch(in: tag, options: [], range: NSRange(location: 0, length: tag.count)) != nil
        let result = res1 && !res2 && !res3 && !res4
        return result
    }
    
    func IsNameValidBeforeTag(name:String) -> Bool {
        let parts = name.components(separatedBy: CharacterSet.init(charactersIn: (SUB_NAME_DELIMITER?.pattern)!))
        if !isRootNameValid(name: parts.first!){
            return false
        }
        if parts.count > 1 {
            for word in parts {
                if !IsSubNameValid(name: word){
                    return false
                }
            }
        }
        return true
    }
    
    func IsAssetNameASubasset(name:String) -> Bool {
        let parts = name.components(separatedBy: CharacterSet.init(charactersIn: (SUB_NAME_DELIMITER?.pattern)!))
        if !isRootNameValid(name: parts.first!){
            return false
        }
        
        return parts.count > 1
    }
    
    /*
     if (std::regex_match(name, UNIQUE_INDICATOR)) {
        if (name.size() > MAX_NAME_LENGTH) return false;
        std::vector<std::string> parts;
        boost::split(parts, name, boost::is_any_of(UNIQUE_TAG_DELIMITER));
        bool valid = IsNameValidBeforeTag(parts.front()) && IsUniqueTagValid(parts.back());
        if (!valid) return false;
        assetType = AssetType::UNIQUE;
        return true;
     }
     */
    
    func IsAssetNameValid(name:String) -> (Bool, AssetType) {
        var assetType:AssetType = .INVALID
        if UNIQUE_INDICATOR?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil {
            if(name.count > MAX_NAME_LENGTH)
            {
                return (false, assetType)
            }
            let parts = name.components(separatedBy: CharacterSet.init(charactersIn: (UNIQUE_TAG_DELIMITER?.pattern)!))
            let valid:Bool = IsNameValidBeforeTag(name: parts.first!) && IsUniqueTagValid(tag: parts.last!)
            if !valid {
               return (false, assetType)
            }
            assetType = .UNIQUE
            return(true, assetType)
        }
        else if CHANNEL_INDICATOR?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil {
            if(name.count > MAX_NAME_LENGTH)
            {
                return (false, assetType)
            }
            let parts = name.components(separatedBy: CharacterSet.init(charactersIn: (CHANNEL_TAG_DELIMITER?.pattern)!))
            let valid:Bool = IsNameValidBeforeTag(name: parts.first!) && IsChannelTagValid(tag: parts.last!)
            if !valid {
                return (false, assetType)
            }
            assetType = .CHANNEL
            return(true, assetType)
        }
        else if OWNER_INDICATOR?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil {
            if(name.count > MAX_NAME_LENGTH)
            {
                return (false, assetType)
            }
            let range = NSMakeRange(0, name.count - 1)
            let valid:Bool = IsNameValidBeforeTag(name: NSString.init(string: name).substring(with: range) )
            if !valid {
                return (false, assetType)
            }
            assetType = .OWNER
            return(true, assetType)
        }
        else {
            if(name.count > MAX_NAME_LENGTH)
            {
                return (false, assetType)
            }
            let valid:Bool = IsNameValidBeforeTag(name: name)
            if !valid {
                return (false, assetType)
            }
            assetType = IsAssetNameASubasset(name: name) ? .SUB : .ROOT
            return(true, assetType)
        }
    }
    
    func validateName(name:String, forType:AssetType) -> Bool {
        let (result, type) = AssetValidator.shared.IsAssetNameValid(name: name)
        if result && forType == type {
            return true
        }
        return false
    }
    
    func IsAssetNameAnOwner(name:String) -> Bool {
        let isOwnerIndicator = OWNER_INDICATOR?.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) != nil
        return IsAssetNameValid(name: name).0 && isOwnerIndicator
    }
    
    
    func IsIpfsHashValid(ipfsHash:String) -> Bool {
        if(ipfsHash.count == MAX_IPFSHASH_LENGTH)
        {
            if IPFSHASH_START?.firstMatch(in: ipfsHash, options: [], range: NSRange(location: 0, length: ipfsHash.count)) != nil {
                return true
            }
        }
        return false
    }
    
    func checkInvalidAsset(asset: BRAssetRef?)->Bool {
        if asset != nil {
            if (asset!.pointee.type != INVALID)
            {
                return true
            }
        }
        return false
    }
    
    func checkNullAsset(asset: BRAssetRef?)->Bool {
        if asset != nil {
            return true
        }
        return false
    }
    
    func getAssetType(operationType:OperationType, nameAsset:String) -> AssetType {
        var assetType:AssetType = .ROOT
        switch operationType {
        case .createAsset:
            if (IsAssetNameAnOwner(name: nameAsset)) {
                assetType = .OWNER
            }
        case .subAsset:
            assetType = .SUB
        case .uniqueAsset:
            assetType = .UNIQUE
        default:
            assetType = .ROOT
        }
        return assetType
    }
}
