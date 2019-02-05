//
//  TutorialVC.swift
//  Ravencoin
//
//  Created by Ben on 11/29/18.
//  Copyright © 2018 Medici Ventures. All rights reserved.
//

import UIKit

struct Page {
    var title: String
    var image: UIImage
    var description: String
}


let PAGES = [
    Page(title: "Welcome to Ravencoin wallet", image: #imageLiteral(resourceName: "Tuto1") , description: "You pay by scanning a QR-code, and receive payments reliably and instantly"),
    Page(title: "12 mnemonic recovery word phrase", image: #imageLiteral(resourceName: "Tuto2") , description: "Back up your funds to ensure you always have access"),
    Page(title: "BTC/Fiat & Gold/Silver", image: #imageLiteral(resourceName: "Tuto3") , description: "Choose your preferred display currency: Settings/Display Currency."),
    Page(title: "Wallet generates new Key pair for every transaction", image: #imageLiteral(resourceName: "Tuto4"), description: "Public address is changed with every transaction, RVN Wallet still manages all keys for you, you can re-use old addresses but this is against best practices"),
    Page(title: "RVN Wallet doesn’t store your money", image: #imageLiteral(resourceName: "Tuto5") , description: "Your money is on the network, the wallet contains keys … a keychain."),
]

class TutorialVC : UIViewController {
    
    init(didTapProceedCreateWallet: (() -> Void)? = nil) {
        self.didTapProceedCreateWallet = didTapProceedCreateWallet
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var pageViewController: UIPageViewController! = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    let pageControl = UIPageControl()
    private let gradiantView = GradientView()
    private let startBtn = ShadowButton(title: S.StartViewController.proceedButton, type: .tertiary)
    private let didTapProceedCreateWallet: (() -> Void)?

    private func addSubviews() {
        view.addSubview(gradiantView)
        view.addSubview(pageViewController.view)
        view.addSubview(startBtn)
        view.addSubview(pageControl)
    }
    
    private func setupSubviewProperties() {
        gradiantView.frame = self.view.frame
        startBtn.isHidden = true
        startBtn.addTarget(self, action: #selector(TutorialVC.tapStart), for: .touchUpInside)
        //UIPageViewController
        pageViewController.view.backgroundColor = .clear
        pageViewController.dataSource = self
        pageViewController.delegate = self
        restartAction(sender: self)
        addChild(self.pageViewController)
        pageViewController.didMove(toParent: self)
        //PageControl
        pageControl.frame = CGRect()
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = .lightGray
        pageControl.numberOfPages = PAGES.count
        pageControl.currentPage = 0
    }
    
    private func addConstraints() {
        startBtn.constrain([
            startBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startBtn.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -C.padding[2]),
            startBtn.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[4]),
            startBtn.heightAnchor.constraint(equalToConstant: C.Sizes.buttonHeight)
            ])
        // pageControl
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.constrain([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: startBtn.topAnchor, constant: -C.padding[1]),
            pageControl.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[4]),
            pageControl.heightAnchor.constraint(equalToConstant: 20)])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setupSubviewProperties()
        addConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.tintColor = .white
    }
    
    @objc func tapStart(sender: AnyObject) {
        didTapProceedCreateWallet!()
    }
    
    func restartAction(sender: AnyObject) {
        self.pageViewController.setViewControllers([self.viewControllerAtIndex(index: 0)], direction: .forward, animated: true, completion: nil)
    }
    
    func viewControllerAtIndex(index: Int) -> ContentViewController {
        if (PAGES.count == 0) || (index >= PAGES.count) {
            return ContentViewController()
        }
        let vc = ContentViewController()
        vc.pageIndex = index
        return vc
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

// MARK: - Page View Controller Data Source & Delegate
extension TutorialVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int
        if (index == 0 || index == NSNotFound) {
            return nil
        }
        index = index - 1
        return self.viewControllerAtIndex(index: index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let vc = viewController as! ContentViewController
        var index = vc.pageIndex as Int
        if (index == NSNotFound) {
            return nil
        }
        index = index + 1
        if (index == PAGES.count) {
            return nil
        }
        return self.viewControllerAtIndex(index: index)
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return PAGES.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let viewControllers = pageViewController.viewControllers {
            let vc = viewControllers[0] as! ContentViewController
            pageControl.currentPage = vc.pageIndex
            startBtn.isHidden = true
            if vc.pageIndex == (PAGES.count - 1) && didTapProceedCreateWallet != nil {
                startBtn.isHidden = false
            }
        }
    }
}

class ContentViewController: UIViewController {
    var pageIndex: Int!
    
    private let titleLabel = UILabel(font: .customMedium(size: 26.0), color: .white)
    private let descriptionLabel = UILabel(font: .customBody(size: 16.0), color: .white)
    private let image = UIImageView()
    
    private func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(image)
    }

    private func setupSubviewProperties() {
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.text = PAGES[self.pageIndex].title
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.text = PAGES[self.pageIndex].description
        image.image = PAGES[self.pageIndex].image
        image.contentMode = .scaleAspectFit
    }
    
    private func addConstraints() {
        titleLabel.constrain([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[2]),
            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[10]),
            titleLabel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1/5)])
        image.constrain([
            image.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            image.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: C.padding[2]),
            image.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[4])])
        descriptionLabel.constrain([
            descriptionLabel.centerXAnchor.constraint(equalTo: image.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: image.bottomAnchor, constant: C.padding[2]),
            descriptionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -C.padding[4]) ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setupSubviewProperties()
        addConstraints()
    }
    
    
}

