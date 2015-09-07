//
//  AggrByDateChartViewController.swift
//  shoppin
//
//  Created by ischuetz on 22/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftCharts

class AggrByDateChartViewController: UIViewController {

    private var chart: Chart? // arc
    
    var monthYearAggregate: GroupMonthYearAggregate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let monthYearAggregate = monthYearAggregate {
            initChart(monthYearAggregate)
        }
    }
    
    private func initChart(monthYearAggregate: GroupMonthYearAggregate) {
        
        // TODO handle other units
        if monthYearAggregate.timePeriod.timeUnit != .Month {
            print("Error: currently only handles months")
            return
        }
        
        let labelSettings = ChartLabelSettings()
        
        let inputDateFormatter = NSDateFormatter()
        inputDateFormatter.dateFormat = "MM yyyy"

        let outputDateFormatter = NSDateFormatter()
        outputDateFormatter.dateFormat = "MMM"
        
        let xValues: [ChartAxisValueDate] = monthYearAggregate.allDates.map {ChartAxisValueDate(date: $0, formatter: outputDateFormatter)}
        
        // For each xValue we need a chart point. If there's no aggregate for a value we create one with total price 0 (no spendings)
        let chartPoints: [ChartPoint] = xValues.map {xValue in
            
            let (_, month, year) = xValue.date.dayMonthYear
            
            return monthYearAggregate.monthYearAggregates.findFirst {monthYearAggregate in // find aggregate
                monthYearAggregate.monthYear.month == month && monthYearAggregate.monthYear.year == year
            }.map {aggr in // create chartpoint for aggregate
                    ChartPoint(x: xValue, y: ChartAxisValueFloat(CGFloat(aggr.totalPrice)))
            } ?? ChartPoint(x: xValue, y: ChartAxisValueFloat(0)) // create 0 value chartpoint if there's no aggregate
        }
        
        let yValues = ChartAxisValuesGenerator.generateYAxisValuesWithChartPoints(chartPoints, minSegmentCount: 4, maxSegmentCount: 8, multiple: 2, axisValueGenerator: {ChartAxisValueFloat($0, formatter: Float.currencyFormatter, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: "Month", settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Spending", settings: labelSettings.defaultVertical()))
        let chartFrame = CGRectMake(view.frame.origin.x, view.frame.origin.y + 50, view.frame.width - 10, 350)
        let chartSettings = ChartSettings()
        chartSettings.top = 10
        chartSettings.trailing = 20
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxis, yAxis, innerFrame) = (coordsSpace.xAxis, coordsSpace.yAxis, coordsSpace.chartInnerFrame)
        
        let lineModel = ChartLineModel(chartPoints: chartPoints, lineColor: UIColor.redColor(), animDuration: 0.5, animDelay: 0)
        
        let chartPointsLineLayer = ChartPointsLineLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, lineModels: [lineModel])
        
        let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.blackColor(), linesWidth: 0.2, dotWidth: 3)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, settings: settings)
        
        let chart = Chart(
            frame: chartFrame,
            layers: [
                xAxis,
                yAxis,
                guidelinesLayer,
                chartPointsLineLayer
            ]
        )
        
        self.view.addSubview(chart.view)
        self.chart = chart
    }
}
