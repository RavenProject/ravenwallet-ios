//
//  SupportCenterContainer.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-05-02.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit
import WebKit

class SupportCenterContainer : UIViewController, WKNavigationDelegate {

    func navigate(to: String) {
        webView.navigate(to: to)
    }

    init(walletManager: WalletManager, apiClient: BRAPIClient) {
        let mountPoint = "/support"
            webView = BRWebViewController(bundleName: "bread-frontend", mountPoint: mountPoint, walletManager: walletManager, noAuthApiClient: apiClient)

        webView.startServer()
        webView.preload()
        super.init(nibName: nil, bundle: nil)
    }

    private let webView: BRWebViewController
    let blur = UIVisualEffectView()

    override func viewDidLoad() {
        view.backgroundColor = .clear
        addChildViewController(webView, layout: {
            webView.view.constrain([
                webView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.view.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
                webView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.view.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor) ])
        })
        addTopCorners()
    }

    private func addTopCorners() {
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 6.0, height: 6.0)).cgPath
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        webView.view.layer.mask = maskLayer
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
