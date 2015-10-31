//
//  StatsDetailsViewController.swift
//  shoppin
//
//  Created by ischuetz on 30/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class StatsDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var aggr: MonthYearAggregate? {
        didSet {
            if let aggr = aggr {
                initAggregates(aggr.monthYear)
                initTitle()
            }
        }
    }
    
    private var productAggregates: [ProductAggregate] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var onViewDidLoad: VoidFunction?
    
    private func initAggregates(monthYear: MonthYear) {
        Providers.statsProvider.aggregate(monthYear, groupBy: GroupByAttribute.Name, successHandler {[weak self] productAggregates in
            self?.productAggregates = productAggregates
        })
    }
    
    private func initTitle() {
        let inputDateFormatter = NSDateFormatter()
        inputDateFormatter.dateFormat = "MMM yy"
        if let date = aggr?.monthYear.toDate() {
            navigationItem.title = inputDateFormatter.stringFromDate(date)
        } else {
            print("Warn: StatsDetailsViewController: aggr not set or month year invalid")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        onViewDidLoad?()
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
}