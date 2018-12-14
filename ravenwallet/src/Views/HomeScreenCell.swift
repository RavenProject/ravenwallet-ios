//
//  HomeScreenCell.swift
//  ravenwallet
//
//  Created by Adrian Corscadden on 2017-11-28.
//  Copyright © 2018 Ravenwallet Team. All rights reserved.
//

import UIKit

class Background : UIView, GradientDrawable {

    var currency: CurrencyDef?

    override func layoutSubviews() {
        super.layoutSubviews()
        let maskLayer = CAShapeLayer()
        let corners: UIRectCorner = .allCorners
        maskLayer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 4.0, height: 4.0)).cgPath
        layer.mask = maskLayer
    }

    override func draw(_ rect: CGRect) {
        guard let currency = currency else { return }
        drawGradient(start: currency.colors.0, end: currency.colors.1, rect)
    }
}

class HomeScreenCell : UITableViewCell, Subscriber {
    
    static let cellIdentifier = "CurrencyCell"

    private let currencyName = UILabel(font: .customBold(size: 18.0), color: .white)
    private let price = UILabel(font: .customBold(size: 14.0), color: .transparentWhiteText)
    private let fiatBalance = UILabel(font: .customBold(size: 18.0), color: .white)
    private let tokenBalance = UILabel(font: .customBold(size: 14.0), color: .transparentWhiteText)
    private let chartTitle = UILabel(font: .customMedium(size: 13.0), color: .white)
    private let syncIndicator = SyncingIndicator(style: .home)
    private let container = Background()
    private let aaChartView: AAChartView = AAChartView()
    private var aaChartModel: AAChartModel = AAChartModel()
    private let separator = UIView(color: .transparentWhiteText)

    private var isSyncIndicatorVisible: Bool = false {
        didSet {
            UIView.crossfade(tokenBalance, syncIndicator, toRight: isSyncIndicatorVisible, duration: 0.3)
            fiatBalance.textColor = isSyncIndicatorVisible ? .disabledWhiteText : .white
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    func set(viewModel: WalletListViewModel) {
        updateDataCell(viewModel: viewModel)
        addSubscriptions()
    }
    
    func refreshAnimations() {
        syncIndicator.pulse()
    }

    private func setupViews() {
        addSubviews()
        addConstraints()
        setupStyle()
    }
    
    private func updateDataCell(viewModel: WalletListViewModel) {
        container.currency = viewModel.currency
        currencyName.text = viewModel.currency.name
        price.text = viewModel.exchangeRate
        fiatBalance.text = viewModel.fiatBalance
        tokenBalance.text = viewModel.tokenBalance
        container.setNeedsDisplay()
        chartModel()
    }
    
    private func chartModel() {
        let chartModel = ChartModel(parentVC: self.parentViewController()!, callback: { elements in
            let prices = elements.map { ($0 as! NSDictionary).object(forKey: "C") }
            let dates = elements.map { (($0 as! NSDictionary).object(forKey: "T") as! String).replacingOccurrences(of: "T00:00:00", with: "") }
            self.aaChartModel = AAChartModel()
                .chartType(.areaSpline)//Can be any of the chart types listed under `AAChartType`.
                .animationType(.easeInSine)
                .title("")//The chart title
                .subtitle("")//The chart subtitle
                .legendEnabled(false)
                .dataLabelEnabled(false)
                .backgroundColor("transparent")
                .axisColor("white")
                .colorsTheme(["#ffffff"])
                .markerRadius(0)
                .categories(dates)
                .series([
                    AASeriesElement()
                        .name("RVN")
                        .data(prices)
                        .toDic()!])
            DispatchQueue.main.async {
                self.aaChartView.aa_drawChartWithChartModel(self.aaChartModel)
            }
        })
        chartModel.getChartData()
    }
    
    private func addSubscriptions(){
        Store.subscribe(self, selector: { $0[self.container.currency!].syncState != $1[self.container.currency!].syncState },
                        callback: { state in
                            switch state[self.container.currency!].syncState {
                            case .connecting:
                                self.isSyncIndicatorVisible = true
                                self.syncIndicator.text = S.SyncingView.connecting
                            case .syncing:
                                self.isSyncIndicatorVisible = true
                                self.syncIndicator.text = S.SyncingView.syncing
                            case .success:
                                self.isSyncIndicatorVisible = false
                            }
        })
        
        Store.subscribe(self, selector: {
            return $0[self.container.currency!].lastBlockTimestamp != $1[self.container.currency!].lastBlockTimestamp },
                        callback: { state in
                            self.syncIndicator.progress = CGFloat(state[self.container.currency!].syncProgress)
        })
    }

    private func addSubviews() {
        contentView.addSubview(container)
        container.addSubview(currencyName)
        container.addSubview(price)
        container.addSubview(fiatBalance)
        container.addSubview(tokenBalance)
        container.addSubview(syncIndicator)
        container.addSubview(aaChartView)
        container.addSubview(separator)
        container.addSubview(chartTitle)

        aaChartView.isClearBackgroundColor = true
        syncIndicator.isHidden = true
    }

    private func addConstraints() {
        container.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1]*0.5,
                                                           left: C.padding[2],
                                                           bottom: -C.padding[1],
                                                           right: -C.padding[2]))
        currencyName.constrain([
            currencyName.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: C.padding[2]),
            currencyName.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[2])
            ])
        price.constrain([
            price.leadingAnchor.constraint(equalTo: currencyName.leadingAnchor),
            price.topAnchor.constraint(equalTo: currencyName.bottomAnchor)
            ])
        fiatBalance.constrain([
            fiatBalance.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -C.padding[2]),
            fiatBalance.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[2]),
            fiatBalance.leadingAnchor.constraint(greaterThanOrEqualTo: currencyName.trailingAnchor, constant: C.padding[1])
            ])
        tokenBalance.constrain([
            tokenBalance.trailingAnchor.constraint(equalTo: fiatBalance.trailingAnchor),
            tokenBalance.topAnchor.constraint(equalTo: fiatBalance.bottomAnchor),
            tokenBalance.leadingAnchor.constraint(greaterThanOrEqualTo: price.trailingAnchor, constant: C.padding[1])
            ])
        
        syncIndicator.constrain([
            syncIndicator.trailingAnchor.constraint(equalTo: fiatBalance.trailingAnchor),
            syncIndicator.topAnchor.constraint(equalTo: fiatBalance.bottomAnchor),
            syncIndicator.leadingAnchor.constraint(greaterThanOrEqualTo: price.trailingAnchor, constant: C.padding[1])
            ])
        
        chartTitle.constrain([
            chartTitle.topAnchor.constraint(equalTo: tokenBalance.bottomAnchor, constant: C.padding[2]),
            chartTitle.trailingAnchor.constraint(equalTo: fiatBalance.trailingAnchor)
            ])
        
        separator.constrain([
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: chartTitle.leadingAnchor, constant: -C.padding[2]),
            separator.centerYAnchor.constraint(equalTo: chartTitle.centerYAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.0) ])
        
        aaChartView.constrain([
            aaChartView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: C.padding[2]),
            aaChartView.topAnchor.constraint(equalTo: chartTitle.bottomAnchor, constant: C.padding[0]),
            aaChartView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: -C.padding[2]),
            aaChartView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: C.padding[2])
            ])
    }

    private func setupStyle() {
        selectionStyle = .none
        backgroundColor = .clear
        chartTitle.text = S.Chart.title
    }
    
    override func prepareForReuse() {
        Store.unsubscribe(self)
    }
    
    deinit {
        Store.unsubscribe(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
