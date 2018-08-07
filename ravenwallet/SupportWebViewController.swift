//
//  ViewController.swift
//  IOS11WebViewTutorial
//
//  Created by Arthur Knopper on 27/12/2017.
//  Copyright © 2017 Arthur Knopper. All rights reserved.
//
import UIKit
import WebKit

class SupportWebViewController: UIViewController, WKNavigationDelegate {
    var webView = WKWebView()
    var url = URL(string: "http://ravenwallet.org/support")
    private let close = UIImageView(image: #imageLiteral(resourceName: "WebClose"))
//    private let logo = UIImageView(image: #imageLiteral(resourceName: "Logo"))
//    private let support = UIImageView(image: #imageLiteral(resourceName: "support"))

    
//    override func loadView() {
//        webView = WKWebView()
//        webView.navigationDelegate = self
////        view = webView
//    }
    
    func navigate(to: String) {
        url = URL(string: "http://ravenwallet.org/\(to)")!
        webView.load(URLRequest(url: url!))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webView, action: #selector(webView.reload))
        toolbarItems = [refresh]
        navigationController?.isToolbarHidden = false
        
        view.backgroundColor = .webBlue
        webView.backgroundColor = .webBlue
        
        view.addSubview(webView)
        view.addSubview(close)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeWebPage(tapGestureRecognizer:)))
        close.isUserInteractionEnabled = true
        close.addGestureRecognizer(tapGestureRecognizer)
        
//        view.addSubview(logo)
//        view.addSubview(support)

        webView.constrain([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.topAnchor.constraint(equalTo: /*view.topAnchor*/close.bottomAnchor/*, constant: C.padding[2]*/),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor) ])

        close.constrain([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor/*, constant: C.padding[2]*/),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            close.widthAnchor.constraint(equalToConstant: 22.0),
            close.heightAnchor.constraint(equalToConstant: 22.0) ])
        
//        support.center = view.center
//        logo.constrain([
//            logo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: C.padding[2]),
//            logo.trailingAnchor.constraint(equalTo: support.trailingAnchor),
//            logo.leadingAnchor.constraint(equalTo: support.leadingAnchor)])
//
//        support.constrain([
//            support.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: C.padding[1])//,
////            support.trailingAnchor.constraint(equalTo: logo.trailingAnchor),
////            support.leadingAnchor.constraint(equalTo: logo.leadingAnchor)
//        ])

        
//        addTopCorners()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func addTopCorners() {
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 6.0, height: 6.0)).cgPath
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        webView.layer.mask = maskLayer
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func closeWebPage(tapGestureRecognizer: UITapGestureRecognizer!) {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true)
    }
}

extension SupportWebViewController : UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissSupportCenterAnimator()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentSupportCenterAnimator()
    }
}

class PresentSupportCenterAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        guard let toViewController = transitionContext.viewController(forKey: .to) as? SupportCenterContainer else { assert(false, "Missing to view controller"); return }
        guard let toView = transitionContext.view(forKey: .to) else { assert(false, "Missing to view"); return }
        let container = transitionContext.containerView
        
        let blur = toViewController.blur
        blur.frame = container.frame
        container.addSubview(blur)
        
        let finalToViewFrame = toView.frame
        toView.frame = toView.frame.offsetBy(dx: 0, dy: toView.frame.height)
        container.addSubview(toView)
        
        
        UIView.spring(duration, animations: {
            blur.effect = UIBlurEffect(style: .dark)
            toView.frame = finalToViewFrame
        }, completion: { _ in
            transitionContext.completeTransition(true)
        })
    }
}

class DismissSupportCenterAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard transitionContext.isAnimated else { return }
        let duration = transitionDuration(using: transitionContext)
        guard let fromView = transitionContext.view(forKey: .from) else { assert(false, "Missing from view"); return }
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? SupportCenterContainer else { assert(false, "Missing to view controller"); return }
        let originalFrame = fromView.frame
        UIView.animate(withDuration: duration, animations: {
            fromViewController.blur.effect = nil
            fromView.frame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
        }, completion: { _ in
            fromView.frame = originalFrame //Because this view gets reused, it's frame needs to be reset everytime
            transitionContext.completeTransition(true)
        })
    }
}
