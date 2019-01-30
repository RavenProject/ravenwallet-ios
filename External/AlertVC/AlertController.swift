//
//  AlertController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-07-04.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

/// Adds ability to display `UIImage` above the Message label of `UIAlertController`.
/// Functionality is achieved by adding “\n” characters to `Message`, to make space
/// for `UIImageView` to be added to `UIAlertController.view`. Set `Message` as
/// normal but when retrieving value use `originalMessage` property.
class AlertController: UIAlertController {
    /// - Return: value that was set on `Message`
    private(set) var originalMessage: String?
    private var spaceAdjustedMessage: String = ""
    private weak var imageView: UIImageView? = nil
    private var previousImgViewSize: CGSize = .zero
    
    override var message: String? {
        didSet {
            // Keep track of original Message
            if message != spaceAdjustedMessage {
                originalMessage = message
            }
        }
    }
    
    /// - parameter image: `UIImage` to be displayed about Message label
    func setMessageImage(_ image: UIImage?) {
        guard let imageView = self.imageView else {
            let imageView = UIImageView(image: image)
            self.view.addSubview(imageView)
            self.imageView = imageView
            return
        }
        imageView.image = image
    }
    
    // MARK: -  Layout code
    
    override func viewDidLayoutSubviews() {
        guard let imageView = imageView else {
            super.viewDidLayoutSubviews()
            return
        }
        // Adjust Message if image size has changed
        if previousImgViewSize != imageView.bounds.size {
            previousImgViewSize = imageView.bounds.size
            adjustMessage(for: imageView)
        }
        // Position `imageView`
        let linesCount = newLinesCount(for: imageView)
        let padding = Constants.padding(for: preferredStyle)
        imageView.center.x = view.bounds.width / 2.0
        imageView.center.y = 2 * padding + linesCount * lineHeight / 2.0
        super.viewDidLayoutSubviews()
    }
    
    /// Adds appropriate number of "\n" to `Message` text to make space for `imageView`
    private func adjustMessage(for imageView: UIImageView) {
        let linesCount = Int(newLinesCount(for: imageView)) + 1
        let lines = (0..<linesCount).map({ _ in "\n" }).reduce("", +)
        spaceAdjustedMessage = lines + (originalMessage ?? "")
        message = spaceAdjustedMessage
    }
    
    /// - Return: Number new line chars needed to make enough space for `imageView`
    private func newLinesCount(for imageView: UIImageView) -> CGFloat {
        return ceil(imageView.bounds.height / lineHeight)
    }
    
    /// Calculated based on system font line height
    private lazy var lineHeight: CGFloat = {
        let style: UIFont.TextStyle = self.preferredStyle == .alert ? .headline : .callout
        return UIFont.preferredFont(forTextStyle: style).pointSize
    }()
    
    struct Constants {
        static var paddingAlert: CGFloat = 22
        static var paddingSheet: CGFloat = 11
        static func padding(for style: UIAlertController.Style) -> CGFloat {
            return style == .alert ? Constants.paddingAlert : Constants.paddingSheet
        }
    }
}
