//
//  StatsViewController.swift
//  shoppin
//
//  Created by ischuetz on 17/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView

private enum StatsType {
    case Aggr, History
}

private enum StatsPresentation {
    case List, Graph
}

class StatsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    private let statsProvider = ProviderFactory().statsProvider
    
    private static let defaultTimePeriod = TimePeriod(quantity: -3, timeUnit: .Month)
    private let timePeriods: [(timePeriod: TimePeriod, text: String)] = [
        (defaultTimePeriod, "3 months"),
        (TimePeriod(quantity: -6, timeUnit: .Month), "6 months")
    ]
    
    @IBOutlet weak var statsContentView: UIView!
    @IBOutlet weak var timePeriodButton: UIButton!
 
    private var sortByPopup: CMPopTipView?
    
    private var currentStatsType: StatsType = .Aggr
    private var currentStatsPresentation: StatsPresentation = .List
    private var currentTimePeriod: TimePeriod = defaultTimePeriod
    
    private let pickerLabelFont = UIFont(name: "HelveticaNeue-Light", size: 17) ?? UIFont.systemFontOfSize(17) // TODO font in 1 place
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showStatsContent()
    }
    
    @IBAction func onStatsTypeSwitch(sender: UISegmentedControl) {
        currentStatsType = sender.selectedSegmentIndex == 0 ? .Aggr : .History
        showStatsContent()
    }
    
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    @IBAction func onStatsPresentationSwitch(sender: UISegmentedControl) {
        currentStatsPresentation = sender.selectedSegmentIndex == 0 ? .List : .Graph
        showStatsContent()
    }
 
    @IBAction func onTimePeriodTap(sender: UIButton) {
        if let popup = self.sortByPopup {
            popup.dismissAnimated(true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(timePeriodButton, inView: view, animated: true)
        }
    }
    
    private func showStatsContent() {
        showStatsContent(currentStatsType, presentation: currentStatsPresentation)
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
        label.font = pickerLabelFont
        label.text = timePeriods[row].text
        return label
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let timePeriod = timePeriods[row]
        currentTimePeriod = timePeriod.timePeriod
        showStatsContent()
        timePeriodButton.setTitle(timePeriod.text, forState: .Normal)
    }
    
    // MARK: - 
    
    private func showStatsContent(type: StatsType, presentation: StatsPresentation) {
        switch (type) {
        case .Aggr:
            statsProvider.aggregate(currentTimePeriod, groupBy: .Name, handler: successHandler{[weak self] productAggregate in
                switch (presentation) {
                case .List:
                    self?.showAggrList(productAggregate)
                case .Graph:
                    self?.showAggrGraph(productAggregate)
                }
            })
        case .History:
            statsProvider.history(currentTimePeriod, group: .All, handler: successHandler{[weak self] groupMonthYearAggregate in
                switch (presentation) {
                case .List:
                    self?.showHistoryList(groupMonthYearAggregate)
                case .Graph:
                    self?.showHistoryGraph(groupMonthYearAggregate)
                }
            })
        }
    }
    

    private func showHistoryList(monthYearAggregate: GroupMonthYearAggregate) {
        let viewController = UIStoryboard.aggrByDateTableViewController()
        viewController.monthYearAggregate = monthYearAggregate
        showStatsContent(viewController)
    }

    private func showHistoryGraph(monthYearAggregate: GroupMonthYearAggregate) {
        let viewController = UIStoryboard.aggrByDateChartViewController()
        viewController.monthYearAggregate = monthYearAggregate
        showStatsContent(viewController)
    }

    private func showAggrList(productAggregates: [ProductAggregate]) {
        let viewController = UIStoryboard.aggrByTypeTableViewController()
        viewController.productAggregates = productAggregates
        showStatsContent(viewController)
    }
    
    private func showAggrGraph(aggregates: [ProductAggregate]) {
        let viewController = UIStoryboard.aggrByTypeChartViewController()
        viewController.productAggregates = aggregates
        showStatsContent(viewController)
    }
    
    private func showStatsContent(viewController: UIViewController) {
        for childViewController in self.childViewControllers {
            childViewController.removeFromParentViewController() // FIXME not so good if for some reason we had other child view controllers
        }
        for subview in self.statsContentView.subviews {
            subview.removeFromSuperview()
        }
        self.addChildViewController(viewController) // TODO is this necessary?
        self.statsContentView.addSubview(viewController.view)
    }
}