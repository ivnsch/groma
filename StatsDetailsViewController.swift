//
//  StatsDetailsViewController.swift
//  shoppin
//
//  Created by ischuetz on 30/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class StatsDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, XYPieChartDataSource, XYPieChartDelegate {

    @IBOutlet weak var pieChartContainer: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var totalSpendLabel: UILabel!
    @IBOutlet weak var totalSpendViewHeightConstraint: NSLayoutConstraint!
    
    var onViewDidLoad: VoidFunction?
    
    private var pieChart: XYPieChart?
    
    private var slices: [Slice] = [] {
        didSet {
            pieChart?.selectedSliceOffsetRadius = slices.count <= 1 ? 0 : 10
        }
    }
    
    var initData: (aggr: MonthYearAggregate, inventory: Inventory)? {
        didSet {
            if let initData = initData {
                initAggregates(initData.aggr.monthYear, inventory: initData.inventory)
                initTitle()
            }
        }
    }
    
    private var productAggregates: [ProductAggregate] = [] {
        didSet {
            tableView?.reloadData()
            
            slices = generateSlices(productAggregates)

            totalSpendLabel.text = spentTotal(productAggregates).toLocalCurrencyString()
            
            initLegends(slices)
            
            pieChart?.reloadData()
        }
    }
    
    private func spentTotal(productAggregates: [ProductAggregate]) -> Float {
        return productAggregates.sum({$0.totalPrice})
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO dynamic
    @IBOutlet weak var circle1: UIView!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var circle2: UIView!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var circle3: UIView!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var circle4: UIView!
    @IBOutlet weak var label4: UILabel!
    @IBOutlet weak var circle5: UIView!
    @IBOutlet weak var label5: UILabel!
    @IBOutlet weak var circle6: UIView!
    @IBOutlet weak var label6: UILabel!
    
    private func initLegends(slices: [Slice]) {
        circle1.hidden = true
        label1.hidden = true
        circle2.hidden = true
        label2.hidden = true
        circle3.hidden = true
        label3.hidden = true
        circle4.hidden = true
        label4.hidden = true
        circle5.hidden = true
        label5.hidden = true
        circle6.hidden = true
        label6.hidden = true
        
        for i in 0..<slices.count {
            let slice = slices[i]
            switch i {
            case 0:
                circle1.backgroundColor = slice.color
                label1.text = slice.text
                circle1.hidden = false
                label1.hidden = false
            case 1:
                circle2.backgroundColor = slice.color
                label2.text = slice.text
                circle2.hidden = false
                label2.hidden = false
            case 2:
                circle3.backgroundColor = slice.color
                label3.text = slice.text
                circle3.hidden = false
                label3.hidden = false
            case 3:
                circle4.backgroundColor = slice.color
                label4.text = slice.text
                circle4.hidden = false
                label4.hidden = false
            case 4:
                circle5.backgroundColor = slice.color
                label5.text = slice.text
                circle5.hidden = false
                label5.hidden = false
            case 5:
                circle6.backgroundColor = slice.color
                label6.text = slice.text
                circle6.hidden = false
                label6.hidden = false
            default: break
            }
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    private func initAggregates(monthYear: MonthYear, inventory: Inventory) {
        Providers.statsProvider.aggregate(monthYear, groupBy: GroupByAttribute.Name, inventory: inventory, successHandler {[weak self] productAggregates in
            self?.productAggregates = productAggregates
        })
    }
    
    private func initTitle() {
        let inputDateFormatter = NSDateFormatter()
        inputDateFormatter.dateFormat = "MMM yyyy"
        if let date = initData?.aggr.monthYear.toDate() {
            navigationItem.title = inputDateFormatter.stringFromDate(date)
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
        QL1("Deinit stats details controller")
    }
    
    private func initPieChart() {
        
        //        let radius: CGFloat = 100
        //        let center = CGPointMake(pieChartContainer.bounds.width / , <#T##y: CGFloat##CGFloat#>)
        let pieChart = XYPieChart(frame: CGRectInset(pieChartContainer.bounds, 0, 0))
        pieChart.pieRadius = DimensionsManager.pieChartRadius
        pieChart.pieCenter = CGPointMake(pieChart.pieRadius + 20, pieChart.pieRadius + 10)
        pieChart.labelRadius = DimensionsManager.pieChartLabelRadius
        //        pieChart.showPercentage = true
        pieChart.showLabel = true
        pieChart.labelFont = Fonts.superSmallLight
        pieChart.labelColor = UIColor.blackColor()
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productAggregates.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("aggrCell", forIndexPath: indexPath) as! ProductAggregateCell
        let aggregate = self.productAggregates[indexPath.row]
        cell.productAggregate = aggregate
        return cell
    }
    
    // MARK: - XYPieChartDataSource

    func numberOfSlicesInPieChart(pieChart: XYPieChart!) -> UInt {
        return UInt(slices.count)
    }
    
    func pieChart(pieChart: XYPieChart!, valueForSliceAtIndex index: UInt) -> CGFloat {
        return CGFloat(slices[Int(index)].value)
    }
    
    func pieChart(pieChart: XYPieChart!, colorForSliceAtIndex index: UInt) -> UIColor! {
        return slices[Int(index)].color
    }
    
    func pieChart(pieChart: XYPieChart!, textForSliceAtIndex index: UInt) -> String! {
//        return slices[Int(index)].text
        return "\(slices[Int(index)].value.toString(1))%"
    }
    
    // MARK: - XYPieChartDelegate
    
    func pieChart(pieChart: XYPieChart!, didSelectSliceAtIndex index: UInt) {
        label1.font = Fonts.superSmallLight
        label2.font = Fonts.superSmallLight
        label3.font = Fonts.superSmallLight
        label4.font = Fonts.superSmallLight
        label5.font = Fonts.superSmallLight
        label6.font = Fonts.superSmallLight
        switch index {
        case 0:
            label1.font = Fonts.superSmallBold
        case 1:
            label2.font = Fonts.superSmallBold
        case 2:
            label3.font = Fonts.superSmallBold
        case 3:
            label4.font = Fonts.superSmallBold
        case 4:
            label5.font = Fonts.superSmallBold
        case 5:
            label6.font = Fonts.superSmallBold
        default: break
        }
    }
    
    func pieChart(pieChart: XYPieChart!, didDeselectSliceAtIndex index: UInt) {
        label1.font = Fonts.superSmallLight
        label2.font = Fonts.superSmallLight
        label3.font = Fonts.superSmallLight
        label4.font = Fonts.superSmallLight
        label5.font = Fonts.superSmallLight
        label6.font = Fonts.superSmallLight
    }
    
    private func generateSlices(aggregates: [ProductAggregate]) -> [Slice] {

        typealias CategoryData = (category: ProductCategory, price: Float, percentage: Float)
        
        let topCount = 5
        
        var categoryDict = OrderedDictionary<String, CategoryData>()
        for aggregate in aggregates {
            if let categoryData = categoryDict[aggregate.product.category.uuid] {
                categoryDict[aggregate.product.category.uuid] = CategoryData(
                    category: aggregate.product.category,
                    price: aggregate.totalPrice + categoryData.price,
                    percentage: aggregate.percentage + categoryData.percentage
                )
            } else {
                categoryDict[aggregate.product.category.uuid] = CategoryData(category: aggregate.product.category, price: aggregate.totalPrice, percentage: aggregate.percentage)
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
        
        var slices: [Slice] = top.enumerate().map{(index, element) in
            Slice(value: element.percentage, text: "\(element.category.name)(\(element.price.toLocalCurrencyString()))", color: element.category.color.colorWithAlphaComponent(0.6))
        }
        
        if restPercentage > 0 {
            let restSlice = Slice(value: restPercentage, text: trans("stats_details_rest", restPrice.toLocalCurrencyString()), color: UIColor.grayColor())
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