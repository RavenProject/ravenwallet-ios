//
//  HomeScreenViewController.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-11-27.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class HomeScreenViewController : UIViewController, Subscriber, Trackable {
    
    var primaryWalletManager: WalletManager? {
        didSet {
            setInitialData()
            setupSubscriptions()
            currencyList.reload()
            attemptShowPrompt()
        }
    }
    private let currencyList = AssetListTableView()
    private let subHeaderView = UIView()
    private var logo: UIImageView = {
//        let image = UIImageView(image: #imageLiteral(resourceName: "LogoGradient"))
        let image = UIImageView(image: #imageLiteral(resourceName: "newLogo"))
        image.contentMode = .scaleAspectFit
        return image
    }()
    private let total = UILabel(font: .customBold(size: 30.0), color: .darkGray)
    private let totalHeader = UILabel(font: .customMedium(size: 18.0), color: .mediumGray)
    private let prompt = UIView()
    private var promptHiddenConstraint: NSLayoutConstraint!

    var didSelectCurrency : ((CurrencyDef) -> Void)?
    var didTapSecurity: (() -> Void)?
    var didTapSupport: (() -> Void)?
    var didTapSettings: (() -> Void)?
    
    // MARK: -
    
    init(primaryWalletManager: WalletManager?) {
        self.primaryWalletManager = primaryWalletManager
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        currencyList.didSelectCurrency = didSelectCurrency
        currencyList.didTapSecurity = didTapSecurity
        currencyList.didTapSupport = didTapSupport
        currencyList.didTapSettings = didTapSettings
        
        addSubviews()
        addConstraints()
        setInitialData()
        setupSubscriptions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + promptDelay) { [weak self] in
            self?.attemptShowPrompt()
        }
    }
    
    // MARK: Setup

    private func addSubviews() {
        view.addSubview(subHeaderView)
        subHeaderView.addSubview(logo)
        subHeaderView.addSubview(totalHeader)
        subHeaderView.addSubview(total)
        view.addSubview(prompt)
    }

    private func addConstraints() {
        let height: CGFloat = 136.0
        if #available(iOS 11.0, *) {
            subHeaderView.constrain([
                subHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                subHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0.0),
                subHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                subHeaderView.heightAnchor.constraint(equalToConstant: height) ])
        } else {
            subHeaderView.constrain([
                subHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                subHeaderView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 0.0),
                subHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                subHeaderView.heightAnchor.constraint(equalToConstant: height) ])
        }
        
        let yConstraint = NSLayoutConstraint(item: logo, attribute: .centerY, relatedBy: .equal, toItem: subHeaderView, attribute: .centerY, multiplier: 0.5, constant: 0.0)
        logo.constrain([
            logo.constraint(.centerX, toView: subHeaderView, constant: nil),
            logo.trailingAnchor.constraint(equalTo: subHeaderView.trailingAnchor, constant: -C.padding[2]),
            logo.leadingAnchor.constraint(equalTo: subHeaderView.leadingAnchor, constant: C.padding[2]),
            yConstraint])
        
        totalHeader.constrain([
            totalHeader.trailingAnchor.constraint(equalTo: total.trailingAnchor),
            totalHeader.bottomAnchor.constraint(equalTo: total.topAnchor, constant: 0.0),
            totalHeader.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: C.padding[2])
            ])
        total.constrain([
            total.trailingAnchor.constraint(equalTo: subHeaderView.trailingAnchor, constant: -C.padding[2]),
//            total.bottomAnchor.constraint(equalTo: subHeaderView.bottomAnchor, constant: -C.padding[2]),
            total.topAnchor.constraint(equalTo: totalHeader.bottomAnchor/*, constant: C.padding[2]*/)])
        
        promptHiddenConstraint = prompt.heightAnchor.constraint(equalToConstant: 0.0)
        prompt.constrain([
            prompt.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            prompt.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            prompt.topAnchor.constraint(equalTo: subHeaderView.bottomAnchor),
            promptHiddenConstraint
            ])
        
        addChildViewController(currencyList, layout: {
            currencyList.view.constrain([
                currencyList.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                currencyList.view.topAnchor.constraint(equalTo: prompt.bottomAnchor),
                currencyList.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                currencyList.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        })
    }

    private func setInitialData() {
        view.backgroundColor = .whiteBackground
        subHeaderView.backgroundColor = .whiteBackground
        subHeaderView.clipsToBounds = false
        
        navigationItem.titleView = UIView()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = #imageLiteral(resourceName: "TransparentPixel")
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "TransparentPixel"), for: .default)
        
        totalHeader.text = S.HomeScreen.totalAssets
        totalHeader.textAlignment = .left
        total.textAlignment = .left
        total.text = "0"
        title = ""
        
        updateTotalAssets()
    }

    private func updateTotalAssets() {
        let fiatTotal = Store.state.currencies.map {
            let balance = Store.state[$0].balance ?? 0
            let rate = Store.state[$0].currentRate?.rate ?? 0
            return Double(balance)/$0.baseUnit * rate * 0.001
        }.reduce(0.0, +)
        
        let format = NumberFormatter()
        format.isLenient = true
        format.numberStyle = .currency
        format.generatesDecimalNumbers = true
        format.negativeFormat = format.positiveFormat.replacingCharacters(in: format.positiveFormat.range(of: "#")!, with: "-#")
        format.currencySymbol = Store.state[Currencies.rvn].currentRate?.currencySymbol ?? ""
        self.total.text = format.string(from: NSNumber(value: fiatTotal))
    }
    
    private func setupSubscriptions() {
        Store.unsubscribe(self)
        
        Store.subscribe(self, selector: {
            var result = false
            let oldState = $0
            let newState = $1
            $0.currencies.forEach { currency in
                if oldState[currency].balance != newState[currency].balance {
                    result = true
                }
                
                if oldState[currency].currentRate?.rate != newState[currency].currentRate?.rate {
                    result = true
                }
            }
            return result
        },
                        callback: { _ in
                            self.updateTotalAssets()
        })
        
        // prompts
        Store.subscribe(self, name: .didUpgradePin, callback: { _ in
            if self.currentPrompt?.type == .upgradePin {
                self.currentPrompt = nil
            }
        })
        Store.subscribe(self, name: .didEnableShareData, callback: { _ in
            if self.currentPrompt?.type == .shareData {
                self.currentPrompt = nil
            }
        })
        Store.subscribe(self, name: .didWritePaperKey, callback: { _ in
            if self.currentPrompt?.type == .paperKey {
                self.currentPrompt = nil
            }
        })
    }
    
    // MARK: - Prompt
    
    private let promptDelay: TimeInterval = 0.6
    
    private var currentPrompt: Prompt? {
        didSet {
            if currentPrompt != oldValue {
                var afterFadeOut: TimeInterval = 0.0
                if let oldPrompt = oldValue {
                    afterFadeOut = 0.15
                    UIView.animate(withDuration: 0.2, animations: {
                        oldValue?.alpha = 0.0
                    }, completion: { _ in
                        oldPrompt.removeFromSuperview()
                    })
                }
                
                if let newPrompt = currentPrompt {
                    newPrompt.alpha = 0.0
                    prompt.addSubview(newPrompt)
                    newPrompt.constrain(toSuperviewEdges: .zero)
                    prompt.layoutIfNeeded()
                    promptHiddenConstraint.isActive = false

                    // fade-in after fade-out and layout
                    UIView.animate(withDuration: 0.2, delay: afterFadeOut + 0.15, options: .curveEaseInOut, animations: {
                        newPrompt.alpha = 1.0
                    })
                } else {
                    promptHiddenConstraint.isActive = true
                }
                
                // layout after fade-out
                UIView.animate(withDuration: 0.2, delay: afterFadeOut, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    private func attemptShowPrompt() {
        guard let walletManager = primaryWalletManager else {
            currentPrompt = nil
            return
        }
        if let type = PromptType.nextPrompt(walletManager: walletManager) {
            self.saveEvent("prompt.\(type.name).displayed")
            currentPrompt = Prompt(type: type)
            currentPrompt!.dismissButton.tap = { [unowned self] in
                self.saveEvent("prompt.\(type.name).dismissed")
                self.currentPrompt = nil
            }
            currentPrompt!.continueButton.tap = { [unowned self] in
                if let trigger = type.trigger(currency: Currencies.rvn) {
                    Store.trigger(name: trigger)
                }
                self.saveEvent("prompt.\(type.name).trigger")
                self.currentPrompt = nil
            }
            if type == .biometrics {
                UserDefaults.hasPromptedBiometrics = true
            }
            if type == .shareData {
                UserDefaults.hasPromptedShareData = true
            }
        } else {
            currentPrompt = nil
        }
    }
    
    // MARK: -

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

