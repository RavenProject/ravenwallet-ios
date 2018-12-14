//
//  Sender.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-01-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class ChartModel {
    
    init(parentVC: UIViewController, callback: @escaping (NSArray) -> Void) {
        self.callback = callback
        self.parentVC = parentVC
    }
    
    let parentVC:UIViewController
    let callback: (NSArray) -> Void

    func getChartData() {
        if !UserDefaults.shouldReloadChart && UserDefaults.isChartDrawed {
            return
        }
        let url = URL(string: "https://international.bittrex.com/Api/v2.0/pub/market/GetTicks?marketName=BTC-RVN&tickInterval=day")
        let request = NSMutableURLRequest(url: url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 20)

        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            guard error == nil else { print("get chart Data error: \(error!)"); return }
            guard let response = response, let data = data else { print("no response or data"); return }
            do {
                if let convertedJsonIntoDict = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    let result:Bool = convertedJsonIntoDict.object(forKey: "success") as! Bool
                    if(result) {
                        UserDefaults.shouldReloadChart = false
                        UserDefaults.isChartDrawed = true
                        let elements:NSArray = convertedJsonIntoDict.object(forKey: "result") as! NSArray
                        self.callback(Array(elements) as NSArray)
                    }
                    else {
                        let message: String = convertedJsonIntoDict.object(forKey: "message") as! String
                        self.showErrorMessage(message)
                    }
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }.resume()

    }
    
    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: S.Alert.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        parentVC.present(alert, animated: true, completion: nil)
    }
}
