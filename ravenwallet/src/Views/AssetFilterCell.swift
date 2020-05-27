//
//  AssetFilterCell.swift
//  Ravencoin
//
//  Created by Austin Hill on 5/17/20.
//  Copyright © 2020 Medici Ventures. All rights reserved.
//

import UIKit

class AssetFilterCell: UITableViewCell {
    static var reuseIdentifier = "assetFilterCell"
    
    var assetName: String? {
        didSet {
            guard let assetName = assetName else { return }
            self.textLabel?.text = assetName
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
