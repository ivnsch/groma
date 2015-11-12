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

private enum StatsType {
    case Aggr, History
}

private enum StatsPresentation {
    case List, Graph
}

class StatsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    private let statsProvider = ProviderFactory().statsProvider
    
    private typealias TimePeriodWithText = (timePeriod: TimePeriod, text: String)
    
    private static let defaultTimePeriod = TimePeriod(quantity: -6, timeUnit: .Month)
    private let timePeriods: [TimePeriodWithText] = [
        (defaultTimePeriod, "6 months"),
        (TimePeriod(quantity: -12, timeUnit: .Month), "12 months")
    ]
    
    @IBOutlet weak var timePeriodButton: UIButton!
    @IBOutlet weak var chartView: ChartBaseView!
    @IBOutlet weak var averageLabel: UILabel!
    
    private var sortByPopup: CMPopTipView?
    
    private var currentStatsType: StatsType = .Aggr
    private var currentStatsPresentation: StatsPresentation = .List
    private var currentTimePeriod: TimePeriod = defaultTimePeriod
    
    private var chart: Chart?
    
    private let gradientPicker: GradientPicker = GradientPicker(width: 200)

    override func viewDidLoad() {
        super.viewDidLoad()
        setTimePeriod(timePeriods[0])
    }
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }

    @IBAction func onTimePeriodTap(sender: UIButton) {
        if let popup = self.sortByPopup {
            popup.dismissAnimated(true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(timePeriodButton, inView: view, animated: true)
        }
    }

    
    // MARK: - UIPicker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timePeriods.count
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = timePeriods[row].text
        return label
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let timePeriod = timePeriods[row]
        setTimePeriod(timePeriod)
    }

    // MARK: -
    
    private func updateChart(timePeriod: TimePeriod) {
        Providers.statsProvider.history(timePeriod, group: AggregateGroup.All, successHandler{[weak self] aggregate in
            self?.initChart(aggregate)
        })
    }
    
    private func setTimePeriod(timePeriod: TimePeriodWithText) {
        currentTimePeriod = timePeriod.timePeriod
        updateChart(timePeriod.timePeriod)
        timePeriodButton.setTitle(timePeriod.text, forState: .Normal)
    }
    
    private func initChart(monthYearAggregate: GroupMonthYearAggregate) {
        
        self.chart?.view.removeSubviews()
        
        if monthYearAggregate.timePeriod.timeUnit != .Month {
            print("Error: currently only handles months")
            return
        }
        
        let labelSettings = ChartLabelSettings(font: Fonts.verySmallLight)
        
        let outputDateFormatter = NSDateFormatter()
        outputDateFormatter.dateFormat = "MMM"
        
        let xValues: [ChartAxisValueDate] = monthYearAggregate.allDates.map {ChartAxisValueDate(date: $0, formatter: outputDateFormatter, labelSettings: labelSettings)}
        
        // For each xValue we need a chart point. If there's no aggregate for a value we create one with total price 0 (no spendings)
        let chartPoints: [AggrChartPoint] = xValues.map {xValue in
            
            let (_, month, year) = xValue.date.dayMonthYear
            
            return monthYearAggregate.monthYearAggregates.findFirst {monthYearAggregate in // find aggregate
                monthYearAggregate.monthYear.month == month && monthYearAggregate.monthYear.year == year
                }.map {aggr in // create chartpoint for aggregate
                    AggrChartPoint(x: xValue, y: ChartAxisValueFloat(CGFloat(aggr.totalPrice)), aggr: aggr)
                } ?? AggrChartPoint(x: xValue, y: ChartAxisValueFloat(0), aggr: nil) // create 0 value chartpoint if there's no aggregate
        }

        let (sum, maxSpendings): (Double, Double) = chartPoints.reduce((Double(0), Double(0))) {tuple, chartPoint in
            
            let newSum = tuple.0 + chartPoint.y.scalar
            let newMax = max(chartPoint.y.scalar, tuple.1)
            
            return (newSum, newMax)
        }
        let avg = CGFloat(sum) / CGFloat(chartPoints.count) // month average
        

        class EmptyAxisValue: ChartAxisValueFloat {
            override var labels: [ChartAxisLabel] {
                return []
            }
        }
        let yValues = ChartAxisValuesGenerator.generateYAxisValuesWithChartPoints(chartPoints, minSegmentCount: 4, maxSegmentCount: 8, multiple: 2, axisValueGenerator: {EmptyAxisValue($0)}, addPaddingSegmentIfEdge: false)
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: "", settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Spending", settings: labelSettings.defaultVertical()))
        let chartFrame = CGRectMake(view.frame.origin.x, view.frame.origin.y + 50, view.frame.width - 10, 350)
        let chartSettings = ChartSettings()
        chartSettings.top = 30
        chartSettings.trailing = 30
        chartSettings.leading = 20
        chartSettings.labelsToAxisSpacingY = 0

        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxis, yAxis, innerFrame) = (coordsSpace.xAxis, coordsSpace.yAxis, coordsSpace.chartInnerFrame)
        
        let cp: [ChartPoint] = xValues.map {xValue in
            let (_, month, year) = xValue.date.dayMonthYear
            let axisValue2: Float = {
                if let aggr = (monthYearAggregate.monthYearAggregates.findFirst {monthYearAggregate in // find aggregate
                    monthYearAggregate.monthYear.month == month && monthYearAggregate.monthYear.year == year
                    }) {
                        return aggr.totalPrice
                } else {
                    return 0
                }
            }()
            return ChartPoint(x: xValue, y: ChartAxisValueFloat(CGFloat(axisValue2)))
        }


        let barWidth = xAxis.minAxisScreenSpace - (xValues.count < 7 ? 25 : 10) // when few values (<7) bars look a bit too wide, make them smaller
        
        
        let barViewGenerator = {(chartPointModel: ChartPointLayerModel<AggrChartPoint>, layer: ChartPointsViewsLayer<AggrChartPoint, UIView>, chart: Chart) -> UIView? in
            let bottomLeft = CGPointMake(layer.innerFrame.origin.x, layer.innerFrame.origin.y + layer.innerFrame.height)
            
            let (p1, p2): (CGPoint, CGPoint) =  (CGPointMake(chartPointModel.screenLoc.x, bottomLeft.y), CGPointMake(chartPointModel.screenLoc.x, chartPointModel.screenLoc.y))

            
            let percentage: CGFloat = {
                let y = CGFloat(chartPointModel.chartPoint.y.scalar)
                if y <= avg {
                    return 0.01
                } else {
                    return ((y - avg) / (CGFloat(maxSpendings) - avg)) - 0.01
                }
            }()
            
            let alpha: CGFloat = 0.7
            let bgColor = self.gradientPicker.colorForPercentage(percentage).colorWithAlphaComponent(alpha)
            
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

        
        // labels layer
        // create chartpoints for the top and bottom of the bars, where we will show the labels
        let labelChartPoints: [ChartPoint] = cp.collect{bar in
            if bar.y.scalar > 0 {
                return ChartPoint(x: bar.x, y: bar.y)
            } else {
                return nil
            }
        }
        
        let formatter = NSNumberFormatter()
        formatter.maximumFractionDigits = 2
        let labelsLayer = ChartPointsViewsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: labelChartPoints, viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
            let label = HandlingLabel()
            let posOffset: CGFloat = 10
            
            let pos = chartPointModel.chartPoint.y.scalar > 0
            
            let yOffset = pos ? -posOffset : posOffset
            label.text = "\(Float(chartPointModel.chartPoint.y.scalar).toLocalCurrencyString())"
            label.font = Fonts.verySmallLight
            label.sizeToFit()
            label.center = CGPointMake(chartPointModel.screenLoc.x, pos ? innerFrame.origin.y : innerFrame.origin.y + innerFrame.size.height)
            label.alpha = 0
            
            label.movedToSuperViewHandler = {[weak label] in
                UIView.animateWithDuration(0.3, animations: {
                    label?.alpha = 1
                    label?.center.y = chartPointModel.screenLoc.y + yOffset
                })
            }
            return label
            
        }, displayDelay: 0.3) // show after bars animation
        
        
        // average layer
        let avgChartPoint = ChartPoint(x: ChartAxisValueFloat(0), y: ChartAxisValueFloat(avg))
        let avgLineDelay: Float = 0.3
        let avgLineDuration = 0.3
        let avgLayer = ChartPointsViewsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, chartPoints: [avgChartPoint], viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
            let line = HandlingView(frame: CGRectMake(xAxis.p1.x, chartPointModel.screenLoc.y, 0, 1))
            line.backgroundColor = UIColor.blueColor()
            line.movedToSuperViewHandler = {
                UIView.animateWithDuration(avgLineDuration) {
                    let extra = barWidth / 2
                    line.frame = CGRectMake(xAxis.p1.x - extra, chartPointModel.screenLoc.y, xAxis.length + extra * 2, 1)
                }
            }
            return line
        }, displayDelay: avgLineDelay)

        averageLabel.alpha = 0
        averageLabel.text = "Average: \(Float(avg).toLocalCurrencyString()) / Month"
        UIView.animateWithDuration(NSTimeInterval(avgLineDuration), delay: NSTimeInterval(avgLineDelay), options: UIViewAnimationOptions.CurveLinear, animations: {[weak self] in
            self?.averageLabel.alpha = 1
        }, completion: nil)

        
        let chart = Chart(
            view: chartView,
            layers: [
                xAxis,
                barsLayer,
                labelsLayer,
                avgLayer
            ]
        )
        
        self.chart = chart
    }

    
    func onBarTap(aggr: MonthYearAggregate) {
        let detailsController = UIStoryboard.statsDetailsViewController()
        detailsController.onViewDidLoad = {
            detailsController.aggr = aggr
        }
        navigationController?.pushViewController(detailsController, animated: true)
        
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