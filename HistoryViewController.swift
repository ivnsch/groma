//
//  HistoryViewController.swift
//  shoppin
//
//  Created by ischuetz on 17/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

final class SectionModel<T> {
    var expanded: Bool
    let obj: T
    
    init(expanded: Bool = false, obj: T) {
        self.expanded = expanded
        self.obj = obj
    }
}

class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, HistoryItemGroupHeaderViewDelegate {

    private let historyProvider = ProviderFactory().historyProvider
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    @IBOutlet var tableViewFooter: LoadingFooter!
    @IBOutlet var tableView: UITableView!
    
    private var sectionModels: [SectionModel<HistoryItemGroup>] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.topInset = 64 // in my understanding this should be 64 which is the actual size of nav bar but it needs 44 for some reason
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        sectionModels = []
        paginator.reset() // TODO improvement either memory cache or reset only if history has changed (marked items as bought since last load)
        loadPossibleNextPage()
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionModels.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionModel = sectionModels[section]
        return sectionModel.expanded ? sectionModel.obj.historyItems.count : 0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionModel = sectionModels[section]
        let group = sectionModel.obj
        let view = NSBundle.loadView("HistoryItemGroupHeaderView", owner: self) as! HistoryItemGroupHeaderView
        
        view.userName = group.user.email
        view.date = "\(group.date)" // TODO format
        view.price = "\(group.totalPrice.toLocalCurrencyString())" // TODO format
        
        view.sectionIndex = section
        view.sectionModel = sectionModel
        view.delegate = self
        
        return view
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("historyCell", forIndexPath: indexPath) as! HistoryItemCell
        
        let historyItem = sectionModels[indexPath.section].obj.historyItems[indexPath.row]
        
        // TODO format price, date
        
        cell.itemNameLabel.text = historyItem.product.name
        cell.itemUnitLabel.text = "\(historyItem.quantity) x \(historyItem.product.price.toLocalCurrencyString())"
        cell.itemPriceLabel.text = (Float(historyItem.quantity) * historyItem.product.price).toLocalCurrencyString()
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("select: \(indexPath)")
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage()
        }
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }

        synced(self) {[weak self] in
            let weakSelf = self!
            
            if !weakSelf.paginator.reachedEnd {
                
                if (!weakSelf.loadingPage) {
                    setLoading(true)
                    
                    weakSelf.historyProvider.historyItemsGroups(weakSelf.paginator.currentPage, weakSelf.successHandler{historyItems in
                        for historyItem in historyItems {
                            weakSelf.sectionModels.append(SectionModel(obj: historyItem))
                        }
                        
                        weakSelf.paginator.update(historyItems.count)
                        
                        weakSelf.tableView.reloadData()
                        setLoading(false)
                    })
                }
            }
        }
    }

    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            // TODO lock? many deletes quickly could cause a crash here. >>> Or remove immediately and rever if failure result
            let historyItem = sectionModels[indexPath.section].obj.historyItems[indexPath.row]
            historyProvider.removeHistoryItem(historyItem, successHandler({result in
                
                tableView.wrapUpdates {[weak self] in
                    if let weakSelf = self {
                        
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                        
                        let group = weakSelf.sectionModels[indexPath.section].obj
                        var historyItems = group.historyItems
                        historyItems.removeAtIndex(indexPath.row)
                        let updatedGroup = group.copy(historyItems: historyItems)
                        weakSelf.sectionModels[indexPath.section] = SectionModel(obj: updatedGroup)
                    }
                }
            }))

        } else if editingStyle == .Insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - HistoryItemGroupHeaderViewDelegate
    
    func onHeaderTap(header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>) {
        setHeaderExpanded(header, sectionIndex: sectionIndex, sectionModel: sectionModel)
    }
    
    private func setHeaderExpanded(header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>) {
        
        let sectionIndexPaths: [NSIndexPath] = (0..<sectionModel.obj.historyItems.count).map {
            return NSIndexPath(forRow: $0, inSection: sectionIndex)
        }
        
        if sectionModel.expanded { // collapse
            tableView.wrapUpdates {[weak self] in
                self?.tableView.deleteRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                sectionModel.expanded = false
            }
        } else { // expand
            tableView.wrapUpdates {[weak self] in
                self?.tableView.insertRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                sectionModel.expanded = true
            }
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: sectionIndex), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
    }
    
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
}
