//
//  StatsViewController.swift
//  shoppin
//
//  Created by ischuetz on 17/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView
import SwiftCharts
import QorumLogs

private enum StatsType {
    case Aggr, History
}

private enum StatsPresentation {
    case List, Graph
}

class StatsViewController: UIViewController
//, UIPickerViewDataSource, UIPickerViewDelegate
{

    private let statsProvider = ProviderFactory().statsProvider
    
    private typealias TimePeriodWithText = (timePeriod: TimePeriod, text: String)
    
    private static let defaultTimePeriod = TimePeriod(quantity: -6, timeUnit: .Month)
    private let timePeriods: [TimePeriodWithText] = [
        (defaultTimePeriod, "6 months"),
        (TimePeriod(quantity: -12, timeUnit: .Month), "12 months")
    ]
    
//    @IBOutlet weak var timePeriodButton: UIButton!
    @IBOutlet weak var chartView: ChartBaseView!
    @IBOutlet weak var averageLabel: UILabel!
    @IBOutlet weak var dailyAverageLabel: UILabel!
    @IBOutlet weak var monthEstimateLabel: UILabel!

    @IBOutlet weak var averageLabelLabel: UILabel!
    @IBOutlet weak var dailyAverageLabelLabel: UILabel!
    @IBOutlet weak var monthEstimateLabelLabel: UILabel!
    
    @IBOutlet weak var emptyStatsView: UIView!

    private var sortByPopup: CMPopTipView?
    
    private var currentStatsType: StatsType = .Aggr
    private var currentStatsPresentation: StatsPresentation = .List
    private var currentTimePeriod: TimePeriod = defaultTimePeriod
    
    private var chart: Chart?
    
    private let gradientPicker: GradientPicker = GradientPicker(width: 200)

    private let avgLineDelay: Float = 0.3
    private let avgLineDuration = 0.3
    
    private var aggregate: GroupMonthYearAggregate?
    
    @IBOutlet weak var inventoriesButton: UIButton!
    private var inventoryPicker: InventoryPicker?
    private var selectedInventory: Inventory? {
        didSet {
            loadChart()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inventoryPicker = InventoryPicker(button: inventoriesButton, view: view) {[weak self] inventory in
            self?.selectedInventory = inventory
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryWithHistoryAfterSave:", name: WSNotificationName.InventoryItemsWithHistoryAfterSave.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProductCategory:", name: WSNotificationName.ProductCategory.rawValue, object: nil)        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadInventories()
    }
    
    private func loadInventories() {
        Providers.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            self?.inventoryPicker?.inventories = inventories
        })
    }
    
    private func loadChart() {
//        let timePeriod = (aggregate?.timePeriod).flatMap{findTimePeriodWithText($0)} ?? timePeriods[0]
        let timePeriod = timePeriods[1]
        setTimePeriod(timePeriod)
    }
    
    // MARK: Time period picker
    
//    private func createPicker() -> UIPickerView {
//        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
//        picker.delegate = self
//        picker.dataSource = self
//        return picker
//    }

//    @IBAction func onTimePeriodTap(sender: UIButton) {
//        if let popup = self.sortByPopup {
//            popup.dismissAnimated(true)
//        } else {
//            let popup = MyTipPopup(customView: createPicker())
//            popup.presentPointingAtView(timePeriodButton, inView: view, animated: true)
//        }
//    }
//
    private func findTimePeriodWithText(timePeriod: TimePeriod) -> TimePeriodWithText? {
        for timePeriodWithText in timePeriods {
            if timePeriodWithText.timePeriod == timePeriod {
                return timePeriodWithText
            }
        }
        return nil
    }
//    
//    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
//        return 1
//    }
//    
//    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        return timePeriods.count
//    }
//    
//    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
//        let label = view as? UILabel ?? UILabel()
//        label.font = Fonts.regularLight
//        label.text = timePeriods[row].text
//        return label
//    }
//    
//    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        let timePeriod = timePeriods[row]
//        setTimePeriod(timePeriod)
//    }

    // MARK: -
    
    private func updateChart(timePeriod: TimePeriod) {
        if let inventory = selectedInventory {
            Providers.statsProvider.history(timePeriod, group: AggregateGroup.All, inventory: inventory, successHandler{[weak self] aggregate in
                if self?.aggregate?.timePeriod != aggregate.timePeriod || self?.aggregate?.monthYearAggregates ?? [] != aggregate.monthYearAggregates { // don't reload if there are no changes
                    self?.emptyStatsView.setHiddenAnimated(!aggregate.monthYearAggregates.isEmpty)
                    self?.aggregate = aggregate
                    
                    if !aggregate.monthYearAggregates.isEmpty {
                        self?.initChart(aggregate)
                        self?.initThisMonthSpendingsLabels(aggregate)
                    }
                }
            })
        } else {
            print("Warn: StatsViewController.updateChart: Can't update chart because there's no selected inventory")
        }
    }
    
    private func setTimePeriod(timePeriod: TimePeriodWithText) {
        currentTimePeriod = timePeriod.timePeriod
        updateChart(timePeriod.timePeriod)
//        timePeriodButton.setTitle(timePeriod.text, forState: .Normal)
    }
    
    private func initThisMonthSpendingsLabels(monthYearAggregate: GroupMonthYearAggregate) {
        if let lastMonthYearAggregate = monthYearAggregate.monthYearAggregates.first { // the spendings of this months (which is always the last in the returned aggregate)
            
            let today = NSDate()
            let dailyAvgSpendingsThisMonth = lastMonthYearAggregate.totalPrice / Float(today.dayMonthYear.day)
            let projectedTotalSpendingsThisMonth = Float(today.daysInMonth) * dailyAvgSpendingsThisMonth
            
            dailyAverageLabel.alpha = 0
            monthEstimateLabel.alpha = 0
            dailyAverageLabelLabel.alpha = 0
            monthEstimateLabelLabel.alpha = 0
            dailyAverageLabel.text = dailyAvgSpendingsThisMonth.toLocalCurrencyString()
            monthEstimateLabel.text = projectedTotalSpendingsThisMonth.toLocalCurrencyString()
            UIView.animateWithDuration(NSTimeInterval(avgLineDuration), delay: NSTimeInterval(avgLineDelay), options: UIViewAnimationOptions.CurveLinear, animations: {[weak self] in
                self?.dailyAverageLabel.alpha = 1
                self?.monthEstimateLabel.alpha = 1
                self?.dailyAverageLabelLabel.alpha = 1
                self?.monthEstimateLabelLabel.alpha = 1
            }, completion: nil)
            
        } else {
            print("Error: StatsViewController.initThisMonthSpendingsLabels no last month")
        }
    }
    
    private func initChart(monthYearAggregate: GroupMonthYearAggregate) {
        
        self.chart?.view.removeSubviews()
        
        if monthYearAggregate.timePeriod.timeUnit != .Month {
            print("Error: currently only handles months")
            return
        }
        
        let labelSettings = ChartLabelSettings(font: Fonts.verySmallLight, fontColor: UIColor.grayColor())
        
        let outputDateFormatter = NSDateFormatter()
        outputDateFormatter.dateFormat = "MMM"
        
        
        
        class MyAxisValueDate: ChartAxisValueDate {
            let isHighlighted: Bool
            init(date: NSDate, formatter: NSDateFormatter, isHighlighted: Bool, labelSettings: ChartLabelSettings = ChartLabelSettings()) {
                self.isHighlighted = isHighlighted
                super.init(date: date, formatter: formatter, labelSettings: labelSettings)
            }
            override var labels: [ChartAxisLabel] {
                let settings: ChartLabelSettings = {
                    if isHighlighted {
                        return labelSettings.copy(fontColor: UIColor.darkTextColor())
                    } else {
                        return labelSettings
                    }
                    
                }()
                let axisLabel = ChartAxisLabel(text: self.description, settings: settings)
                return [axisLabel]
            }
        }
        
        let firstDateWithData = monthYearAggregate.monthYearAggregates.findFirst {$0.totalCount > 0}

        let xValues: [MyAxisValueDate] = monthYearAggregate.allDates.map {date in
            // highlight active months: >= the first date where there are data entries
            let isHighlighted: Bool = {
                if let firstDateWithData = firstDateWithData {
                    let (_, aggrMonth, aggrYear) = date.dayMonthYear
                    let aggrMonthYear = MonthYear(month: aggrMonth, year: aggrYear)
                    return aggrMonthYear >= firstDateWithData.monthYear
                } else {
                    return false
                }
            }()
            return MyAxisValueDate(date: date, formatter: outputDateFormatter, isHighlighted: isHighlighted, labelSettings: labelSettings)
        }
        
        // For each xValue we need a chart point. If there's no aggregate for a value we create one with total price 0 (no spendings)
        let chartPoints: [AggrChartPoint] = xValues.map {xValue in
            
            let (_, month, year) = xValue.date.dayMonthYear
            
            return monthYearAggregate.monthYearAggregates.findFirst {monthYearAggregate in // find aggregate
                monthYearAggregate.monthYear.month == month && monthYearAggregate.monthYear.year == year
                }.map {aggr in // create chartpoint for aggregate
                    AggrChartPoint(x: xValue, y: ChartAxisValueDouble(Double(aggr.totalPrice)), aggr: aggr)
                } ?? AggrChartPoint(x: xValue, y: ChartAxisValueDouble(0), aggr: nil) // create 0 value chartpoint if there's no aggregate
        }

        
        
        
        let (sum, maxSpendings): (Double, Double) = chartPoints.reduce((Double(0), Double(0))) {tuple, chartPoint in
            
            let newSum = tuple.0 + chartPoint.y.scalar
            let newMax = max(chartPoint.y.scalar, tuple.1)
            
            return (newSum, newMax)
        }
        
        let monthlyAverage: Double = {
            if let firstDateWithData = firstDateWithData {
                let activeMonthsCount = monthYearAggregate.monthYearAggregates.filter{$0.monthYear >= firstDateWithData.monthYear}.count
                return sum / Double(activeMonthsCount)
            } else {
                return 0
            }
        }()

        class EmptyAxisValue: ChartAxisValueDouble {
            override var labels: [ChartAxisLabel] {
                return []
            }
        }

        let yValues: [ChartAxisValue] = ChartAxisValuesGenerator.generateYAxisValuesWithChartPoints(chartPoints, minSegmentCount: 4, maxSegmentCount: 8, multiple: 2, axisValueGenerator: {EmptyAxisValue($0)}, addPaddingSegmentIfEdge: false)
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: "", settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Spending", settings: labelSettings.defaultVertical()))
        let chartSettings = ChartSettings()
        chartSettings.top = 20
        chartSettings.trailing = 20
        chartSettings.leading = 10
        chartSettings.labelsToAxisSpacingY = 0
        chartSettings.axisStrokeWidth = 0
        
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartView.bounds, xModel: xModel, yModel: yModel)
        let (xAxis, yAxis, innerFrame) = (coordsSpace.xAxis, coordsSpace.yAxis, coordsSpace.chartInnerFrame)
        
        let cp: [ChartPoint] = xValues.map {xValue in
            let (_, month, year) = xValue.date.dayMonthYear
            let axisValue2: Double = {
                if let aggr = (monthYearAggregate.monthYearAggregates.findFirst {monthYearAggregate in // find aggregate
                    monthYearAggregate.monthYear.month == month && monthYearAggregate.monthYear.year == year
                    }) {
                        return Double(aggr.totalPrice)
                } else {
                    return 0
                }
            }()
            return ChartPoint(x: xValue, y: ChartAxisValueDouble(axisValue2))
        }


        let barWidth = xAxis.minAxisScreenSpace - (xValues.count < 7 ? 25 : 10) // when few values (<7) bars look a bit too wide, make them smaller
        
        
        let barViewGenerator = {(chartPointModel: ChartPointLayerModel<AggrChartPoint>, layer: ChartPointsViewsLayer<AggrChartPoint, UIView>, chart: Chart) -> UIView? in
            let bottomLeft = CGPointMake(layer.innerFrame.origin.x, layer.innerFrame.origin.y + layer.innerFrame.height)
            
            let (p1, p2): (CGPoint, CGPoint) =  (CGPointMake(chartPointModel.screenLoc.x, bottomLeft.y), CGPointMake(chartPointModel.screenLoc.x, chartPointModel.screenLoc.y))

            
//            let percentage: CGFloat = {
//                let y = CGFloat(chartPointModel.chartPoint.y.scalar)
//                if y <= avg {
//                    return 0.01
//                } else {
//                    return ((y - avg) / (CGFloat(maxSpendings) - avg)) - 0.01
//                }
//            }()
            
            let alpha: CGFloat = 0.7
            let bgColor = Theme.orange
            let barView = MyChartPointViewBar(p1: p1, p2: p2, width: barWidth, bgColor: bgColor)
            
            barView.onViewTap = {[weak self] in
                
                if let aggr = chartPointModel.chartPoint.aggr {
                    self?.onBarTap(aggr)
                } else {
                    print("Error: invalid state: tapping a bar without aggr (bars without aggregate means there's no data for axis value which means bar's height is 0 which means is not tappable.")
                }
                
                barView.backgroundColor = barView.backgroundColor?.colorWithAlphaComponent(0.5)
                delay(0.5) {
                    barView.backgroundColor = barView.backgroundColor?.colorWithAlphaComponent(alpha)
                }
            }
            
            return barView
        }
        let barsLayer = ChartPointsViewsLayer<AggrChartPoint, UIView>(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: chartPoints, viewGenerator: barViewGenerator)
        
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 2
        let labelsLayer = ChartPointsViewsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: cp, viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
            
            if chartPointModel.index == cp.count - 1 && chartPointModel.chartPoint.y.scalar > 0 {
                let label = HandlingLabel()
                
                let yOffset: CGFloat = -15
                label.text = "\(Float(chartPointModel.chartPoint.y.scalar).toLocalCurrencyString())"
                label.font = Fonts.superSmall
                label.textColor = UIColor.darkGrayColor()
                label.sizeToFit()
                label.center = CGPointMake(chartPointModel.screenLoc.x, innerFrame.origin.y)
                label.alpha = 0
                
                label.movedToSuperViewHandler = {[weak label] in
                    UIView.animateWithDuration(0.3, animations: {
                        label?.alpha = 1
                        label?.center.y = chartPointModel.screenLoc.y + yOffset
                    })
                }
                return label
            } else {
                return nil
            }

        }, displayDelay: 0.3) // show after bars animation
        
        let layers: [ChartLayer] = [xAxis, barsLayer, labelsLayer]

//        if (chartPoints.contains{$0.y.scalar > 0}) { // don't show avg line if all the prices are 0, it looks weird
        
            // average line for now disabled
//            // average layer
//            let avgChartPoint = ChartPoint(x: ChartAxisValueFloat(0), y: ChartAxisValueFloat(avg))
//            let avgLayer = ChartPointsViewsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: [avgChartPoint], viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
//                let line = HandlingView(frame: CGRectMake(xAxis.p1.x, chartPointModel.screenLoc.y, 0, 1))
//                line.backgroundColor = UIColor.blueColor()
//                line.movedToSuperViewHandler = {[weak self] in
//                    if let weakSelf = self {
//                        UIView.animateWithDuration(weakSelf.avgLineDuration) {
//                            let extra = barWidth / 2
//                            line.frame = CGRectMake(xAxis.p1.x - extra, chartPointModel.screenLoc.y, xAxis.length + extra * 2, 1)
//                        }
//                    }
//                }
//                return line
//            }, displayDelay: avgLineDelay)
            
            averageLabel.alpha = 0
            averageLabelLabel.alpha = 0
            averageLabel.text = monthlyAverage.toLocalCurrencyString()
            UIView.animateWithDuration(NSTimeInterval(avgLineDuration), delay: NSTimeInterval(avgLineDelay), options: UIViewAnimationOptions.CurveLinear, animations: {[weak self] in
                self?.averageLabel.alpha = 1
                self?.averageLabelLabel.alpha = 1
                }, completion: nil)
            
//            layers.append(avgLayer)
//        }

        let chart = Chart(
            view: chartView,
            layers: layers
        )
        
        self.chart = chart
    }

    
    func onBarTap(aggr: MonthYearAggregate) {
        if let inventory = selectedInventory {
            let detailsController = UIStoryboard.statsDetailsViewController()
            detailsController.onViewDidLoad = {
                detailsController.initData = (aggr, inventory)
            }
            navigationController?.pushViewController(detailsController, animated: true)
        } else {
            print("Warn: StatsViewController.onBarTap: Can't show detail view because there's no selected inventory")
        }
    }
    
    // This is called when added items to inventory / history, which means the chart has to be updated
    func onWebsocketInventoryWithHistoryAfterSave(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSEmptyNotification> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadChart()
                default: print("Error: InventoryItemsViewController.onWebsocketInventoryWithHistoryAfterSave: History: not implemented: \(notification.verb)")
                }
            }
        }
    }
    
    func onWebsocketProduct(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    loadChart()
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    loadChart()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketProductCategory(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadChart()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    loadChart()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            print("Error: ViewController.onWebsocketProduct: no userInfo")
        }
    }
    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        loadChart()
    }
}

private class AggrChartPoint: ChartPoint {
    let aggr: MonthYearAggregate?
    
    required init(x: ChartAxisValue, y: ChartAxisValue, aggr: MonthYearAggregate?) {
        self.aggr = aggr
        super.init(x: x, y: y)
    }

    required init(x: ChartAxisValue, y: ChartAxisValue) {
        fatalError("init(x:y:) has not been implemented")
    }
}

class MyChartPointViewBar: ChartPointViewBar {
    
    var onViewTap: VoidFunction?
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        onViewTap?()
    }
}

private class GradientPicker {
    
    let gradientImg: UIImage
    
    lazy var imgData: UnsafePointer<UInt8> = {
        let provider = CGImageGetDataProvider(self.gradientImg.CGImage)
        let pixelData = CGDataProviderCopyData(provider)
        return CFDataGetBytePtr(pixelData)
    }()
    
    init(width: CGFloat) {
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRectMake(0, 0, width, 1)
        gradient.colors = [UIColor.greenColor().CGColor, UIColor.redColor().CGColor]
        gradient.startPoint = CGPointMake(0, 0.5)
        gradient.endPoint = CGPointMake(1.0, 0.5)
        
        let imgHeight = 1
        let imgWidth = Int(gradient.bounds.size.width)
        
        let bitmapBytesPerRow = imgWidth * 4
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue).rawValue
        
        let context = CGBitmapContextCreate (nil,
            imgWidth,
            imgHeight,
            8,
            bitmapBytesPerRow,
            colorSpace,
            bitmapInfo)
        
        UIGraphicsBeginImageContext(gradient.bounds.size)
        gradient.renderInContext(context!)
        
        let gradientImg = UIImage(CGImage: CGBitmapContextCreateImage(context)!)
        
        UIGraphicsEndImageContext()
        self.gradientImg = gradientImg
    }
    
    func colorForPercentage(percentage: CGFloat) -> UIColor {
        
        let data = self.imgData
        
        let xNotRounded = self.gradientImg.size.width * percentage
        let x = 4 * (floor(abs(xNotRounded / 4)))
        let pixelIndex = Int(x * 4)
        
        let color = UIColor(
            red: CGFloat(data[pixelIndex + 0]) / 255.0,
            green: CGFloat(data[pixelIndex + 1]) / 255.0,
            blue: CGFloat(data[pixelIndex + 2]) / 255.0,
            alpha: CGFloat(data[pixelIndex + 3]) / 255.0
        )
        return color
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}