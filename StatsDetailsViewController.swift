//
//  StatsDetailsViewController.swift
//  shoppin
//
//  Created by ischuetz on 30/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

class StatsDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, XYPieChartDataSource, XYPieChartDelegate {

    @IBOutlet weak var pieChartContainer: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var totalSpendLabel: UILabel!
    @IBOutlet weak var totalSpendViewHeightConstraint: NSLayoutConstraint!
    
    var onViewDidLoad: VoidFunction?
    
    fileprivate var pieChart: XYPieChart?
    
    fileprivate var slices: [Slice] = [] {
        didSet {
            pieChart?.selectedSliceOffsetRadius = slices.count <= 1 ? 0 : 10
        }
    }
    
    var initData: (aggr: MonthYearAggregate, inventory: DBInventory)? {
        didSet {
            if let initData = initData {
                initAggregates(initData.aggr.monthYear, inventory: initData.inventory)
                initTitle()
            }
        }
    }
    
    fileprivate var productAggregates: [ProductAggregate] = [] {
        didSet {
            tableView?.reloadData()
            
            slices = generateSlices(productAggregates)

            totalSpendLabel.text = spentTotal(productAggregates).toLocalCurrencyString()
            
            initLegends(slices)
            
            pieChart?.reloadData()
        }
    }
    
    fileprivate func spentTotal(_ productAggregates: [ProductAggregate]) -> Float {
        return productAggregates.sum({$0.totalPrice})
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO dynamic
    @IBOutlet weak var circle1: UIView!
    @IBOutlet weak var label1: LabelMore!
    @IBOutlet weak var circle2: UIView!
    @IBOutlet weak var label2: LabelMore!
    @IBOutlet weak var circle3: UIView!
    @IBOutlet weak var label3: LabelMore!
    @IBOutlet weak var circle4: UIView!
    @IBOutlet weak var label4: LabelMore!
    @IBOutlet weak var circle5: UIView!
    @IBOutlet weak var label5: LabelMore!
    @IBOutlet weak var circle6: UIView!
    @IBOutlet weak var label6: LabelMore!
    
    fileprivate func initLegends(_ slices: [Slice]) {
        circle1.isHidden = true
        label1.isHidden = true
        circle2.isHidden = true
        label2.isHidden = true
        circle3.isHidden = true
        label3.isHidden = true
        circle4.isHidden = true
        label4.isHidden = true
        circle5.isHidden = true
        label5.isHidden = true
        circle6.isHidden = true
        label6.isHidden = true
        
        for i in 0..<slices.count {
            let slice = slices[i]
            switch i {
            case 0:
                circle1.backgroundColor = slice.color
                label1.text = slice.text
                circle1.isHidden = false
                label1.isHidden = false
            case 1:
                circle2.backgroundColor = slice.color
                label2.text = slice.text
                circle2.isHidden = false
                label2.isHidden = false
            case 2:
                circle3.backgroundColor = slice.color
                label3.text = slice.text
                circle3.isHidden = false
                label3.isHidden = false
            case 3:
                circle4.backgroundColor = slice.color
                label4.text = slice.text
                circle4.isHidden = false
                label4.isHidden = false
            case 4:
                circle5.backgroundColor = slice.color
                label5.text = slice.text
                circle5.isHidden = false
                label5.isHidden = false
            case 5:
                circle6.backgroundColor = slice.color
                label6.text = slice.text
                circle6.isHidden = false
                label6.isHidden = false
            default: break
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    fileprivate func initAggregates(_ monthYear: MonthYear, inventory: DBInventory) {
        Prov.statsProvider.aggregate(monthYear, groupBy: GroupByAttribute.name, inventory: inventory, successHandler {[weak self] productAggregates in
            self?.productAggregates = productAggregates
        })
    }
    
    fileprivate func initTitle() {
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "MMM yyyy"
        if let date = initData?.aggr.monthYear.toDate() {
            navigationItem.title = inputDateFormatter.string(from: date as Date)
        } else {
            print("Warn: StatsDetailsViewController: aggr not set or month year invalid")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initPieChart()
        
        totalSpendViewHeightConstraint.constant = DimensionsManager.listItemsPricesViewHeight
        tableView.bottomInset = totalSpendViewHeightConstraint.constant + 10 // 10 just add some extra space

        onViewDidLoad?()
    }
    
    deinit {
        logger.v("Deinit stats details controller")
    }
    
    fileprivate func initPieChart() {
        
        //        let radius: CGFloat = 100
        //        let center = CGPointMake(pieChartContainer.bounds.width / , <#T##y: CGFloat##CGFloat#>)
        let pieChart = XYPieChart(frame: pieChartContainer.bounds.insetBy(dx: 0, dy: 0))
        pieChart.pieRadius = DimensionsManager.pieChartRadius
        pieChart.pieCenter = CGPoint(x: pieChart.pieRadius + 20, y: pieChart.pieRadius + 10)
        pieChart.labelRadius = DimensionsManager.pieChartLabelRadius
        //        pieChart.showPercentage = true
        pieChart.showLabel = true
        
        let font: UIFont = {
            if let fontSize = LabelMore.mapToFontSize(20) {
                return UIFont.systemFont(ofSize: fontSize)
            } else {
                return UIFont.systemFont(ofSize: 13)
            }
        }()

        pieChart.labelFont = font
        pieChart.labelColor = UIColor.black
        //        pieChart.pieCenter = CGPointMake(100, 100)
        pieChartContainer.addSubview(pieChart)
        pieChart.dataSource = self
        pieChart.delegate = self
        pieChart.reloadData()
        self.pieChart = pieChart
  
        
        
        // Center gap, for now disabled since when chart has very large slices (e.g. has only 2) when tapping on them looks bad.
//        let centerDiam: CGFloat = 110
        
        // FIXME!! + 20 (10 in case of y) because this is the offset we pass to pieCenter and + 15 because the radius we pass (85) is 15 less than the default - TODO calculate this correctly! Apparently the pieCenter is not updated ?
//        let x = pieChart.pieCenter.x - centerDiam / 2 + 20 + 15
//        let y = pieChart.pieCenter.y - centerDiam / 2 + 10 + 15
        
//        let centerView = UIView(frame: CGRectMake(x, y, centerDiam, centerDiam))
//        centerView.layer.cornerRadius = centerDiam / 2
//        centerView.backgroundColor = UIColor.whiteColor()
//        pieChartContainer.addSubview(centerView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productAggregates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "aggrCell", for: indexPath) as! ProductAggregateCell
        let aggregate = self.productAggregates[(indexPath as NSIndexPath).row]
        cell.productAggregate = aggregate
        return cell
    }
    
    // MARK: - XYPieChartDataSource

    func numberOfSlices(in pieChart: XYPieChart!) -> UInt {
        return UInt(slices.count)
    }
    
    func pieChart(_ pieChart: XYPieChart!, valueForSliceAt index: UInt) -> CGFloat {
        return CGFloat(slices[Int(index)].value)
    }
    
    func pieChart(_ pieChart: XYPieChart!, colorForSliceAt index: UInt) -> UIColor! {
        return slices[Int(index)].color
    }
    
    func pieChart(_ pieChart: XYPieChart!, textForSliceAt index: UInt) -> String! {
//        return slices[Int(index)].text
        return "\(slices[Int(index)].value.toString(1))%"
    }
    
    // MARK: - XYPieChartDelegate
    
    func pieChart(_ pieChart: XYPieChart!, didSelectSliceAt index: UInt) {
        label1.makeFontRegular()
        label2.makeFontRegular()
        label3.makeFontRegular()
        label4.makeFontRegular()
        label5.makeFontRegular()
        label6.makeFontRegular()
        switch index {
        case 0:
            label1.makeFontBold()
        case 1:
            label2.makeFontBold()
        case 2:
            label3.makeFontBold()
        case 3:
            label4.makeFontBold()
        case 4:
            label5.makeFontBold()
        case 5:
            label6.makeFontBold()
        default: break
        }
    }
    
    func pieChart(_ pieChart: XYPieChart!, didDeselectSliceAt index: UInt) {
        label1.makeFontRegular()
        label2.makeFontRegular()
        label3.makeFontRegular()
        label4.makeFontRegular()
        label5.makeFontRegular()
        label6.makeFontRegular()
    }
    
    fileprivate func generateSlices(_ aggregates: [ProductAggregate]) -> [Slice] {

        typealias CategoryData = (category: ProductCategory, price: Float, percentage: Float)
        
        let topCount = 5
        
        var categoryDict = OrderedDictionary<String, CategoryData>()
        for aggregate in aggregates {
            if let categoryData = categoryDict[aggregate.product.item.category.uuid] {
                categoryDict[aggregate.product.item.category.uuid] = CategoryData(
                    category: aggregate.product.item.category,
                    price: aggregate.totalPrice + categoryData.price,
                    percentage: aggregate.percentage + categoryData.percentage
                )
            } else {
                categoryDict[aggregate.product.item.category.uuid] = CategoryData(category: aggregate.product.item.category, price: aggregate.totalPrice, percentage: aggregate.percentage)
            }
        }
        
        var categoryDataArr: [CategoryData] = []
        for i in (0..<categoryDict.count) {
            categoryDataArr.append(categoryDict[i].1)
        }
        
        let top = categoryDataArr[0..<min(topCount, categoryDataArr.count)]
        let rest: [CategoryData] = {
            if topCount < categoryDataArr.count {
                return Array(categoryDataArr[topCount..<categoryDataArr.count])
            } else {
                return []
            }
        }()

        let (restPercentage, restPrice): (Float, Float) = rest.reduce((0, 0)) {tuple, aggr in
            (tuple.0 + aggr.percentage, tuple.1 + aggr.price)
        }
        
        var slices: [Slice] = top.enumerated().map{(index, element) in
            Slice(value: element.percentage, text: "\(element.category.name)(\(element.price.toLocalCurrencyString()))", color: element.category.color.withAlphaComponent(0.6))
        }
        
        if restPercentage > 0 {
            let restSlice = Slice(value: restPercentage, text: trans("stats_details_rest", restPrice.toLocalCurrencyString()), color: UIColor.gray)
            slices.append(restSlice)
        }

        return slices
    }

}

private struct Slice {
    let value: Float
    let text: String
    let color: UIColor
    
    init(value: Float, text: String, color: UIColor) {
        self.value = value
        self.text = text
        self.color = color
    }
}
