//
//  AddressBookFooterView.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2016-11-16.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class AddressBookFooterView: UIView, Subscriber {

    var addAddressCallback: (() -> Void)?
    var receiveCallback: (() -> Void)?

    private var hasSetup = false
    private let toolbar = UIToolbar()
    
    init() {
        super.init(frame: .zero)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !hasSetup else { return }
        setup()
        hasSetup = true
    }

    private func setup() {
        let separator = UIView(color: .separatorGray)
        addSubview(toolbar)
        addSubview(separator)
        
        toolbar.clipsToBounds = true // to remove separator line
        toolbar.isOpaque = true
        
        // constraints
        toolbar.constrain(toSuperviewEdges: nil)
        separator.constrainTopCorners(height: 0.5)
        
        setupToolbarButtons()
    }
    
    private func setupToolbarButtons() {
        // buttons
        var buttonCount: Int
        
        //MyAddressButton
        let myAddress = UIButton.rounded(title: S.Button.myAddress)
        myAddress.tintColor = .white
        myAddress.backgroundColor = .blue
        myAddress.addTarget(self, action: #selector(AddressBookFooterView.myAddress), for: .touchUpInside)
        let myAddressButton = UIBarButtonItem(customView: myAddress)

        //AddButton
        let addAddress = UIButton.rounded(title: S.Button.addAddress)
        addAddress.tintColor = .white
        addAddress.backgroundColor = .blue
        addAddress.addTarget(self, action: #selector(AddressBookFooterView.addAddressBook), for: .touchUpInside)
        let addAddressButton = UIBarButtonItem(customView: addAddress)
        
        let paddingWidth = C.padding[2]
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
            toolbar.items = [
                flexibleSpace,
                addAddressButton,
                flexibleSpace,
                myAddressButton,
                flexibleSpace,
            ]
            buttonCount = 2
        
        let buttonWidth = (self.bounds.width - (paddingWidth * CGFloat(buttonCount+1))) / CGFloat(buttonCount)
        let buttonHeight = CGFloat(44.0)
        [addAddressButton, myAddressButton].forEach {
            $0.customView?.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight)
        }
    }

    @objc private func addAddressBook() { addAddressCallback?() }
    
    @objc private func myAddress() { receiveCallback?() }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
}
