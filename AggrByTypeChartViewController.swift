//
//  AggrByTypeChartControllerViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class AggrByTypeChartViewController: UIViewController, XYPieChartDataSource {

    private var pieChart: XYPieChart?

    private let top: Int = 6
    
    private var slices: [Slice] = []

    var productAggregates: [ProductAggregate] = [] {
        didSet {
            slices = generateSlices(productAggregates)
            pieChart?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let inset: CGFloat = 10
        let pieChart = XYPieChart(frame: CGRectInset(self.view.frame, inset, inset))
        pieChart.pieCenter = CGPointMake((self.view.frame.width - (inset * 2)) / 2, pieChart.pieRadius + 10)
        pieChart.labelRadius = 100
        pieChart.showPercentage = true
        pieChart.labelFont = UIFont.systemFontOfSize(16)
        pieChart.labelColor = UIColor.blackColor()
        self.view.addSubview(pieChart)
        pieChart.dataSource = self
        pieChart.reloadData()
        
        self.pieChart = pieChart
    }

    func numberOfSlicesInPieChart(pieChart: XYPieChart!) -> UInt {
        return UInt(self.top + 1)
    }
    
    func pieChart(pieChart: XYPieChart!, valueForSliceAtIndex index: UInt) -> CGFloat {
        return CGFloat(slices[Int(index)].value)
    }
    
    func pieChart(pieChart: XYPieChart!, colorForSliceAtIndex index: UInt) -> UIColor! {
        return slices[Int(index)].color
    }
    
    func pieChart(pieChart: XYPieChart!, textForSliceAtIndex index: UInt) -> String! {
        return slices[Int(index)].text
    }
    
    private func generateSlices(aggregates: [ProductAggregate]) -> [Slice] {
        
        let colors = [
            UIColor.yellowColor(),
            UIColor.redColor(),
            UIColor.greenColor(),
            UIColor.blueColor(),
            UIColor.cyanColor(),
            UIColor.magentaColor()
        ].map{$0.colorWithAlphaComponent(0.6)}
        
        let topCount = colors.count // just making sure we don't get out of bounds bc forget to update the colors array

        let top = aggregates[0..<topCount]
        let rest = aggregates[topCount..<aggregates.count]
        
        let restPercentage: Float = rest.reduce(0) {sum, aggr in
            sum + aggr.product.price
        }
        
        var slices: [Slice] = top.enumerate().map{(index, element) in
            Slice(value: element.percentage, text: "\(element.percentage)%", color: colors[index])
        }
        
        let restSlice = Slice(value: restPercentage, text: "\(restPercentage)%", color: UIColor.grayColor())
        slices.append(restSlice)
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