//
//  BRAPIClient+Wallet.swift
//  ravenwallet
//
//  Created by Samuel Sutch on 4/2/17.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import Foundation
import Core

private let fallbackRatesURL = "https://bitpay.com/api/rates"
private let ravenMultiplierURL = "https://api.bittrex.com/v3/markets/RVN-BTC/ticker"

extension BRAPIClient {
    
    func me() {
        let req = URLRequest(url: url("/me"))
        let task = dataTaskWithRequest(req, authenticated: true, handler: { data, response, err in
            if let data = data {
                print("me: \(String(describing: String(data: data, encoding: .utf8)))")
            }
        })
        task.resume()
    }
    
    //    func feePerKb(code: String, _ handler: @escaping (_ fees: Fees, _ error: String?) -> Void) {
    //        let param = ""
    //        let req = URLRequest(url: url("/fee-per-kb\(param)"))
    //        let task = self.dataTaskWithRequest(req) { (data, response, err) -> Void in
    //            var regularFeePerKb: uint_fast64_t = 0
    //            var economyFeePerKb: uint_fast64_t = 0
    //            var errStr: String? = nil
    //            if err == nil {
    //                do {
    //                    let parsedObject: Any? = try JSONSerialization.jsonObject(
    //                        with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
    //                    if let top = parsedObject as? NSDictionary, let regular = top["fee_per_kb"] as? NSNumber, let economy = top["fee_per_kb_economy"] as? NSNumber {
    //                        regularFeePerKb = regular.uint64Value
    //                        economyFeePerKb = economy.uint64Value
    //                    }
    //                } catch (let e) {
    //                    self.log("fee-per-kb: error parsing json \(e)")
    //                }
    //                if regularFeePerKb == 0 || economyFeePerKb == 0 {
    //                    errStr = "invalid json"
    //                }
    //            } else {
    //                self.log("fee-per-kb network error: \(String(describing: err))")
    //                errStr = "bad network connection"
    //            }
    //            handler(Fees(regular: regularFeePerKb, economy: economyFeePerKb, timestamp: Date().timeIntervalSince1970), errStr)
    //        }
    //        task.resume()
    //    }
    
    func ravenMultiplier(_ handler: @escaping (_ mult: Optional<Double>, _ error: String?) -> Void) {
        print("Getting rate from ravenMultiplierURL")
        let request = URLRequest(url: URL(string: ravenMultiplierURL)!)
        let task = dataTaskWithRequest(request) { (data, response, error) in
            do {
                if error == nil,
                    let data = data,
                    let parsedData = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]  {
                    
                    if let lastTradeRate = parsedData["lastTradeRate"] as? String {
                        //print("lastTradeRate \(lastTradeRate)")
                        guard let ratio: Double = Double(lastTradeRate) else {
                            return handler(0.00, "Error getting RVN rate in BTC")
                        }

                        print("Bittrex Ratio of BTC to RVN\(ratio)");
                        return handler(ratio, nil)
                    }
                } else {
                    return handler(0.00, "Error fetching Ravencoin BTC price from Bittrex.")
                }
                
                
            } catch let error {
                return handler(0.00, "Bittrex Ravencoin BTC price error caught \(error)");
            }
        }
        task.resume()
    }
    
    func exchangeRates(code: String, isFallback: Bool = false, _ ratio : Double, _ handler: @escaping (_ rates: [Rate],
        _ multiplier: Double, _ error: String?) -> Void) {
        let param = ""
        let request = isFallback ? URLRequest(url: URL(string: fallbackRatesURL)!) : URLRequest(url: url("/rates\(param)"))
        let task = dataTaskWithRequest(request) { (data, response, error) in
            if error == nil, let data = data,
                let parsedData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                if isFallback {
                    guard let array = parsedData as? [Any] else {
                        return handler([], 1.0, "/rates didn't return an array")
                    }
                    handler(array.compactMap { Rate(dictionary: $0, ratio: ratio) }, 1.0, nil)
                } else {
                    guard let dict = parsedData as? [String: Any],
                        let array = dict["body"] as? [Any] else {
                            return self.exchangeRates(code: code, isFallback: true, ratio, handler)
                    }
                    handler(array.compactMap { Rate(dictionary: $0, ratio: ratio) }, 1.0, nil)
                }
            } else {
                if isFallback {
                    handler([], 1.0, "Error fetching from fallback url")
                } else {
                    self.exchangeRates(code: code, isFallback: true, ratio, handler)
                }
            }
        }
        task.resume()
    }
    
    func savePushNotificationToken(_ token: Data) {
        var req = URLRequest(url: url("/me/push-devices"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let reqJson = [
            "token": token.hexString,
            "service": "apns",
            "data": [   "e": pushNotificationEnvironment(),
                        "b": Bundle.main.bundleIdentifier!]
            ] as [String : Any]
        do {
            let dat = try JSONSerialization.data(withJSONObject: reqJson, options: .prettyPrinted)
            req.httpBody = dat
        } catch (let e) {
            log("JSON Serialization error \(e)")
            return
        }
        dataTaskWithRequest(req as URLRequest, authenticated: true, retryCount: 0) { (dat, resp, er) in
            let dat2 = String(data: dat ?? Data(), encoding: .utf8)
            self.log("save push token resp: \(String(describing: resp)) data: \(String(describing: dat2))")
            }.resume()
    }
    
    func deletePushNotificationToken(_ token: Data) {
        var req = URLRequest(url: url("/me/push-devices/apns/\(token.hexString)"))
        req.httpMethod = "DELETE"
        dataTaskWithRequest(req as URLRequest, authenticated: true, retryCount: 0) { (dat, resp, er) in
            self.log("delete push token resp: \(String(describing: resp))")
            if let statusCode = resp?.statusCode {
                if statusCode >= 200 && statusCode < 300 {
                    UserDefaults.pushToken = nil
                    self.log("deleted old token")
                }
            }
            }.resume()
    }
    
    //    private let mainURL = "https://api.ravencoin.org/api/addrs/utxo"
    //    private let fallbackURL = "https://api.ravencoin.org/api/addrs/utxo"
    func fetchUTXOS(address: String, isAsset:Bool, completion: @escaping ([[String: Any]]?)->Void) {
        let path = isAsset ? String(format: C.fetchAssetUtxosPath, address) : String(format: C.fetchRvnUtxosPath, address)
        // TODO: take testnet in consideration
        //        let path = "http://api.testnet.ravencoin.org/api/addrs/utxo"
        var req = URLRequest(url: URL(string: path)!)
        req.httpMethod = "GET"
        //req.httpBody = "addrs=\(address)".data(using: .utf8)
        dataTaskWithRequest(req, handler: { data, resp, error in
            guard error == nil else { completion(nil); return }
            guard let data = data,
                let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonData as? [[String: Any]]
                else {
                    completion(nil);
                    return
            }
            completion(json)
        }).resume()
    }
    
    func isAddressUsed(address: String, completion: @escaping (Bool)->Void) {
        let path = String(format: C.fetchTxsPath, address)
        var req = URLRequest(url: URL(string: path)!)
        req.httpMethod = "GET"
        //req.httpBody = "addrs=\(address)".data(using: .utf8)
        dataTaskWithRequest(req, handler: { data, resp, error in
            guard error == nil else { completion(false); return }
            guard let data = data,
                let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonData as? [String: Any]
                else {
                    completion(false);
                    return
            }
            let txList:Array = json["transactions"] as! [String]
            if(txList.count != 0){
                completion(true);
            }else {
                completion(false);
            }
        }).resume()
    }
}

private func pushNotificationEnvironment() -> String {
    return E.isDebug ? "d" : "p" //development or production
}
