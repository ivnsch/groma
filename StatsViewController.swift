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

import Providers

private enum StatsType {
    case aggr, history
}

private enum StatsPresentation {
    case list, graph
}

class StatsViewController: UIViewController
//, UIPickerViewDataSource, UIPickerViewDelegate
{
    
    fileprivate typealias TimePeriodWithText = (timePeriod: TimePeriod, text: String)
    
    fileprivate static let defaultTimePeriod = TimePeriod(quantity: -6, timeUnit: .month)
    fileprivate let timePeriods: [TimePeriodWithText] = [
        (defaultTimePeriod, "6 months"),
        (TimePeriod(quantity: -12, timeUnit: .month), "12 months")
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

    fileprivate var sortByPopup: CMPopTipView?
    
    fileprivate var currentStatsType: StatsType = .aggr
    fileprivate var currentStatsPresentation: StatsPresentation = .list
    fileprivate var currentTimePeriod: TimePeriod = defaultTimePeriod
    
    fileprivate var chart: Chart?
    
    fileprivate let gradientPicker: GradientPicker = GradientPicker(width: 200)

    fileprivate let avgLineDelay: Float = 0.3
    fileprivate let avgLineDuration = 0.3
    
    fileprivate var aggregate: GroupMonthYearAggregate?
    
    @IBOutlet weak var inventoriesButton: UIButton!
    fileprivate var inventoryPicker: InventoryPicker?
    fileprivate var selectedInventory: DBInventory? {
        didSet {
            loadChart()
            clearFirstMonthIfIncomplete()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initPicker()
        
        NotificationCenter.default.addObserver(self, selector: #selector(StatsViewController.onWebsocketListItem(_:)), name: NSNotification.Name(rawValue: WSNotificationName.ListItem.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StatsViewController.onWebsocketProduct(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Product.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StatsViewController.onWebsocketProductCategory(_:)), name: NSNotification.Name(rawValue: WSNotificationName.ProductCategory.rawValue), object: nil)        
        NotificationCenter.default.addObserver(self, selector: #selector(StatsViewController.onIncomingGlobalSyncFinished(_:)), name: NSNotification.Name(rawValue: WSNotificationName.IncomingGlobalSyncFinished.rawValue), object: nil)

        Notification.subscribe(.realmSwapped, selector: #selector(InventoriesTableViewController.onRealmSwapped(_:)), observer: self)
    }

    fileprivate func initPicker() {
        inventoryPicker = InventoryPicker(button: inventoriesButton, controller: self) {[weak self] inventory in
            self?.selectedInventory = inventory
        }
    }

    @objc func onRealmSwapped(_ note: Foundation.Notification) {
        loadInventories()
    }

    deinit {
        logger.v("Deinit stats controller")
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadInventories()
    }
    
    // TODO this logic is messy and for now disabled. Is there a reliable way to delete possible first incomplete month? - accross multiple devices, installations, shared users
    fileprivate func clearFirstMonthIfIncomplete() {
        guard !(PreferencesManager.loadPreference(PreferencesManagerKey.clearedFirstIncompleteMonthStats) ?? false) else {
            logger.d("Already cleared first incomplete month, nothing to do")
            return
        }
        
        guard !(PreferencesManager.loadPreference(PreferencesManagerKey.cancelledClearFirstIncompleteMonthStats) ?? false) else {
            logger.d("User cancelled to clear the first incomplete stats months, skipping")
            return
        }
        guard let inventory = selectedInventory else {logger.w("No inventory"); return}

        // Get the date of the oldest history item
        Prov.statsProvider.oldestDate(inventory, resultHandler(onSuccess: {[weak self] oldestDate in guard let weakSelf = self else {return}
            if let firstLaunchDate: Date = PreferencesManager.loadPreference(PreferencesManagerKey.firstLaunchDate) {
                
                let oldestDateDayMonthYear = oldestDate.dayMonthYear
                let firstLaunchDateDayMonthYear = firstLaunchDate.dayMonthYear
                
                // PROBLEM: This algorithm isn't entirely safe and can remove months that are complete:
                // if installation month == current oldest month && installed after first && today is more than 1 month after oldest month -> delete oldest month
                // Consider situation: With 3 months usage, user cleared on device A the oldest month (month 1). Now user on device B, where installed the app in month 2 (a day different than the 1st) and is in month 3 now (1 month after current oldest date (month 2)), will also delete month 2, which is actually complete.
                // As a compromise, not seeing for now another solution, adjusting text in popup to leave decision to the user - "if the previous month was incomplete..."
                
                guard oldestDateDayMonthYear.month == firstLaunchDateDayMonthYear.month && oldestDateDayMonthYear.year == firstLaunchDateDayMonthYear.year else {
                    // The only way we can currently know if first month may be incomplete if by checking the app installation date. This is limited though, if user reinstalled app or is using multiple devices it doesn't necessarily match. In this case we just skip our check, user will have to notice average issue themselves and delete items from history manually.
                    logger.d("Oldest date month/year != installation date month/year. Can't make assumptions about first month completeness")
                    return
                }
                
                // If we are after oldest month.
                if Date().dayMonthYear.month - oldestDateDayMonthYear.month > 1 {
                    
                    let oldestDateMonthYear = MonthYear(month: oldestDateDayMonthYear.month, year: oldestDateDayMonthYear.year)
                    
                    // if the app was installed on the 1st, we assume the first month was complete, so we don't clear it.
                    if firstLaunchDate.dayMonthYear.day != 1 {
                        
                        // If there's actually data for this month, otherwise there's nothing to remove so we don't bother user asking
                        Prov.statsProvider.hasDataForMonthYear(oldestDateMonthYear, inventory: inventory, handler: weakSelf.successHandler{hasData in
                            MyPopupHelper.showPopup(
                                parent: weakSelf,
                                type: .warning,
                                title: "First month start",
                                message: "Congrats! You started a complete month report. If the previous month is incomplete (you didn't use the app the full month) you can remove it now, to improve the average calculations.",
                                okText: trans("popup_button_remove"),
                                centerYOffset: 80, onOk: {
                                    Prov.statsProvider.clearMonthYearData(oldestDateMonthYear, inventory: inventory, remote: true, handler: weakSelf.successHandler{[weak self] in
                                        PreferencesManager.savePreference(PreferencesManagerKey.clearedFirstIncompleteMonthStats, value: true)
                                        self?.loadChart()
                                    })
                            }, onCancel: {
                                PreferencesManager.savePreference(PreferencesManagerKey.cancelledClearFirstIncompleteMonthStats, value: true)
                            }
                            )
                        })
                        
                    } else {
                        logger.d("Different month than installation month but installed at day 1 - nothing to do")
                    }
                    
                } else {
                    logger.d("Same month as installation month")
                }
            }
 
        }, onError: {[weak self] result in
            self?.defaultErrorHandler([.notFound])(result)
        }))
    }
    
    fileprivate func loadInventories() {
        Prov.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            self?.inventoryPicker?.inventories = inventories.toArray()
            self?.showIsEmpty(inventories.isEmpty)
        })
    }
    
    fileprivate func loadChart() {
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

//    @IBAction func onTimePeriodTap(sender: UIButton) {
//        if let popup = self.sortByPopup {
//            popup.dismissAnimated(true)
//        } else {
//            let popup = MyTipPopup(customView: createPicker())
//            popup.presentPointingAtView(timePeriodButton, inView: view, animated: true)
//        }
//    }
//
    fileprivate func findTimePeriodWithText(_ timePeriod: TimePeriod) -> TimePeriodWithText? {
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
    
    fileprivate func updateChart(_ timePeriod: TimePeriod) {
        if let inventory = selectedInventory {
            Prov.statsProvider.history(timePeriod, group: AggregateGroup.all, inventory: inventory, successHandler{[weak self] aggregate in
                if self?.aggregate?.timePeriod != aggregate.timePeriod || self?.aggregate?.monthYearAggregates ?? [] != aggregate.monthYearAggregates { // don't reload if there are no changes
                    self?.showIsEmpty(!aggregate.monthYearAggregates.isEmpty)
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

    fileprivate func showIsEmpty(_ isEmpty: Bool) {
        emptyStatsView.setHiddenAnimated(!isEmpty)
    }

    fileprivate func setTimePeriod(_ timePeriod: TimePeriodWithText) {
        currentTimePeriod = timePeriod.timePeriod
        updateChart(timePeriod.timePeriod)
//        timePeriodButton.setTitle(timePeriod.text, forState: .Normal)
    }
    
    fileprivate func initThisMonthSpendingsLabels(_ monthYearAggregate: GroupMonthYearAggregate) {
        if let lastMonthYearAggregate = monthYearAggregate.monthYearAggregates.last { // the spendings of this month (which is always the last in the returned aggregate)
            
            let today = Date()
            let dailyAvgSpendingsThisMonth = lastMonthYearAggregate.totalPrice / Float(today.dayMonthYear.day)
            let projectedTotalSpendingsThisMonth = Float(today.daysInMonth) * dailyAvgSpendingsThisMonth
            
            dailyAverageLabel.alpha = 0
            monthEstimateLabel.alpha = 0
            dailyAverageLabelLabel.alpha = 0
            monthEstimateLabelLabel.alpha = 0
            dailyAverageLabel.text = dailyAvgSpendingsThisMonth.toLocalCurrencyString()
            monthEstimateLabel.text = projectedTotalSpendingsThisMonth.toLocalCurrencyString()
            UIView.animate(withDuration: TimeInterval(avgLineDuration), delay: TimeInterval(avgLineDelay), options: UIViewAnimationOptions.curveLinear, animations: {[weak self] in
                self?.dailyAverageLabel.alpha = 1
                self?.monthEstimateLabel.alpha = 1
                self?.dailyAverageLabelLabel.alpha = 1
                self?.monthEstimateLabelLabel.alpha = 1
            }, completion: nil)
            
        } else {
            print("Error: StatsViewController.initThisMonthSpendingsLabels no last month")
        }
    }
    
    fileprivate func initChart(_ monthYearAggregate: GroupMonthYearAggregate) {
        
        self.chart?.view.removeSubviews()
        
        if monthYearAggregate.timePeriod.timeUnit != .month {
            print("Error: currently only handles months")
            return
        }
        
        let font: UIFont = {
//            if DimensionsManager.widthDimension == .Small {
                if let fontSize = LabelMore.mapToFontSize(20) {
                    return UIFont.systemFont(ofSize: fontSize)
                } else {
                    logger.e("No font for size")
                    return UIFont.systemFont(ofSize: 10)
                }
//            } else {
//                
//                if let fontSize = LabelMore.mapToFontSize(30) {
//                    return UIFont.systemFontOfSize(fontSize)
//                } else {
//                    logger.e("No font for size")
//                    return UIFont.systemFontOfSize(12)
//                }
//            }
        }()
        
//        let rotation: CGFloat = DimensionsManager.widthDimension == .Small ? 45 : 0
        let rotation: CGFloat = 0
        let labelSettings = ChartLabelSettings(font: font, fontColor: UIColor.gray, rotation: rotation, rotationKeep: .top)
        
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateFormat = "MMM"
        

        class MyAxisValueDate: ChartAxisValueDate {
            let isHighlighted: Bool
            init(date: Date, formatter: DateFormatter, isHighlighted: Bool, labelSettings: ChartLabelSettings = ChartLabelSettings()) {
                self.isHighlighted = isHighlighted
                super.init(date: date, formatter: {formatter.string(from: $0)}, labelSettings: labelSettings)
            }
            override var labels: [ChartAxisLabel] {
                let settings: ChartLabelSettings = {
                    if isHighlighted {
                        var labelSettingsVar = labelSettings
                        labelSettingsVar.fontColor = UIColor.darkText
                        return labelSettingsVar
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

        let (sum, _): (Double, Double) = chartPoints.reduce((Double(0), Double(0))) {tuple, chartPoint in
            
            let newSum = tuple.0 + chartPoint.y.scalar
            let newMaxSpendings = max(chartPoint.y.scalar, tuple.1)
            
            return (newSum, newMaxSpendings)
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

        let yValues: [ChartAxisValue] = ChartAxisValuesStaticGenerator.generateYAxisValuesWithChartPoints(chartPoints, minSegmentCount: 4, maxSegmentCount: 8, multiple: 2, axisValueGenerator: {EmptyAxisValue($0)}, addPaddingSegmentIfEdge: false)
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: "", settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "", settings: labelSettings.defaultVertical()))
        var chartSettings = ChartSettings()
        chartSettings.top = 20
        chartSettings.trailing = 30
        chartSettings.leading = 12
        chartSettings.labelsToAxisSpacingY = 0
        chartSettings.axisStrokeWidth = 0
        chartSettings.clipInnerFrame = false
        
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartView.bounds, xModel: xModel, yModel: yModel)
        let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
        
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


        let barWidth = xAxisLayer.minAxisScreenSpace - (xValues.count < 7 ? 25 : 10) // when few values (<7) bars look a bit too wide, make them smaller
        
        
        let barViewGenerator = {(chartPointModel: ChartPointLayerModel<AggrChartPoint>, layer: ChartPointsViewsLayer<AggrChartPoint, UIView>, chart: Chart) -> UIView? in
            let bottomLeft = layer.modelLocToScreenLoc(x: 0, y: 0)

            let (p1, p2): (CGPoint, CGPoint) =  (CGPoint(x: chartPointModel.screenLoc.x, y: bottomLeft.y), CGPoint(x: chartPointModel.screenLoc.x, y: chartPointModel.screenLoc.y))

//            let percentage: CGFloat = {
//                let y = CGFloat(chartPointModel.chartPoint.y.scalar)
//                if y <= avg {
//                    return 0.01
//                } else {
//                    return ((y - avg) / (CGFloat(maxSpendings) - avg)) - 0.01
//                }
//            }()
            
            let bgColor = Theme.orange
            let barSettings = ChartBarViewSettings()
            let barView = MyChartPointViewBar(p1: p1, p2: p2, width: barWidth, bgColor: bgColor, settings: barSettings)
            
            barView.onViewTap = {[weak self] in
                
                if let aggr = chartPointModel.chartPoint.aggr {
                    self?.onBarTap(aggr)
                } else {
                    print("Error: invalid state: tapping a bar without aggr (bars without aggregate means there's no data for axis value which means bar's height is 0 which means is not tappable.")
                }
                
                barView.backgroundColor = barView.backgroundColor?.withAlphaComponent(0.5)
                delay(0.5) {
                    barView.backgroundColor = barView.backgroundColor?.withAlphaComponent(1)
                }
            }
            
            return barView
        }
        let barsLayer = ChartPointsViewsLayer<AggrChartPoint, UIView>(xAxis: xAxisLayer.axis,
                                                                      yAxis: yAxisLayer.axis,
                                                                      chartPoints: chartPoints,
                                                                      viewGenerator: barViewGenerator,
                                                                      clipViews: false)
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        let barTotalLabelFont: UIFont = {   
            if let fontSize = LabelMore.mapToFontSize(20) {
                return UIFont.systemFont(ofSize: fontSize)
            } else {
                logger.e("No font for size")
                return UIFont.systemFont(ofSize: 11)
            }
        }()
        
        let labelsLayer = ChartPointsViewsLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, chartPoints: cp, viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
            
            if chartPointModel.index == cp.count - 1 && chartPointModel.chartPoint.y.scalar > 0 {
                let label = HandlingLabel()
                
                let yOffset: CGFloat = -15
                label.text = "\(Float(chartPointModel.chartPoint.y.scalar).toLocalCurrencyString())"
                label.font = barTotalLabelFont
                label.textColor = UIColor.darkGray
                label.sizeToFit()
                label.center = CGPoint(x: chartPointModel.screenLoc.x, y: innerFrame.origin.y)
                label.alpha = 0
                
                label.movedToSuperViewHandler = {[weak label] in
                    UIView.animate(withDuration: 0.3, animations: {
                        label?.alpha = 1
                        label?.center.y = chartPointModel.screenLoc.y + yOffset
                    })
                }
                return label
            } else {
                return nil
            }

        }, displayDelay: 0.3) // show after bars animation
        
        let layers: [ChartLayer] = [xAxisLayer, yAxisLayer, barsLayer, labelsLayer]

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
            UIView.animate(withDuration: TimeInterval(avgLineDuration), delay: TimeInterval(avgLineDelay), options: UIViewAnimationOptions.curveLinear, animations: {[weak self] in
                self?.averageLabel.alpha = 1
                self?.averageLabelLabel.alpha = 1
                }, completion: nil)
            
//            layers.append(avgLayer)
//        }

        let chart = Chart(
            view: chartView,
            innerFrame: innerFrame,
            settings: chartSettings,
            layers: layers
        )
        
        self.chart = chart
    }

    
    func onBarTap(_ aggr: MonthYearAggregate) {
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
    
    @objc func onWebsocketListItem(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<RemoteBuyCartResult>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .BuyCart:
                    loadChart()
                    
                default: logger.e("Not handled: \(notification.verb)")
                }
            } else {
                logger.e("Mo value")
            }
            
        } else {
            logger.e("No userInfo")
        }
    }
    
    @objc func onWebsocketProduct(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    loadChart()
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                logger.e("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    loadChart()
                case .DeleteWithBrand:
                    loadChart()
                default: logger.e("Not handled case: \(notification.verb))")
                }
            } else {
                logger.e("No value")
            }
        } else {
            logger.e("No userInfo")
        }
    }
    
    @objc func onWebsocketProductCategory(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadChart()
                default: logger.e("Not handled case: \(notification.verb))")
                }
            } else {
                logger.e("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    loadChart()
                default: logger.e("Not handled case: \(notification.verb))")
                }
            } else {
                logger.e("No value")
            }
        } else {
            print("Error: ViewController.onWebsocketProduct: no userInfo")
        }
    }
    
    @objc func onIncomingGlobalSyncFinished(_ note: Foundation.Notification) {
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onViewTap?()
    }
}

private class GradientPicker {
    
    let gradientImg: UIImage
    
    lazy var imgData: UnsafePointer<UInt8> = {
        let provider = self.gradientImg.cgImage?.dataProvider
        let pixelData = provider?.data
        return CFDataGetBytePtr(pixelData)
    }()
    
    init(width: CGFloat) {
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: width, height: 1)
        gradient.colors = [UIColor.flatGreen.cgColor, UIColor.flatRed.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        let imgHeight = 1
        let imgWidth = Int(gradient.bounds.size.width)
        
        let bitmapBytesPerRow = imgWidth * 4
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue
        
        let context = CGContext (data: nil,
            width: imgWidth,
            height: imgHeight,
            bitsPerComponent: 8,
            bytesPerRow: bitmapBytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo)
        
        UIGraphicsBeginImageContext(gradient.bounds.size)
        gradient.render(in: context!)
        
        let gradientImg = UIImage(cgImage: (context?.makeImage()!)!)
        
        UIGraphicsEndImageContext()
        self.gradientImg = gradientImg
    }
    
    func colorForPercentage(_ percentage: CGFloat) -> UIColor {
        
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
