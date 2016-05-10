//
//  HelpViewController.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class HelpItemSectionModel: SectionModel<HelpItem> {
    var boldRange: NSRange?
    var textHeight: CGFloat? // calculate text size only once, since this is a bit expensive
    init(expanded: Bool = false, obj: HelpItem, boldRange: NSRange? = nil, textHeight: CGFloat? = nil) {
        self.boldRange = boldRange
        super.init(expanded: expanded, obj: obj)
    }
}

class HelpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, HelpHeaderViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UITextField!
    
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!

    private var sectionModels: [HelpItemSectionModel] = [] {
        didSet {
            filteredModels = sectionModels
        }
    }
    
    private var filteredModels: [HelpItemSectionModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.addTarget(self, action: #selector(HelpViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        searchBarHeightConstraint.constant = DimensionsManager.searchBarHeight
        
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(HelpViewController.handleTap(_:)))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        
        Providers.helpProvider.helpItems(successHandler {[weak self] helpItems in
            self?.sectionModels = helpItems.map{HelpItemSectionModel(obj: $0)}
        })
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return filteredModels.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionModel = filteredModels[section]
        return sectionModel.expanded ? 1 : 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! HelpCell
        let sectionModel = self.filteredModels[indexPath.section]
        cell.sectionModel = sectionModel
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = NSBundle.loadView("HelpHeaderView", owner: self) as! HelpHeaderView
        let sectionModel = self.filteredModels[section]
        view.sectionModel = sectionModel
        view.delegate = self
        view.sectionIndex = section
        // height now calculated yet so we pass the position of border
        view.addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
        return view
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let sectionModel = self.filteredModels[indexPath.section]
        if let textHeight = sectionModel.textHeight {
            return textHeight
        } else {
            let textHeight = sectionModel.obj.text.heightWithConstrainedWidth(view.frame.size.width, font: Fonts.fontForSizeCategory(40))
                + 16 + 50 // label top & bottom constrain to cell. 50 is a quick fix, for some reson the returned height is a bit short. TODO fix heightWithConstrainedWidth to return correct height
            sectionModel.textHeight = textHeight
            return textHeight
        }
    }
    
    // MARK: - HelpHeaderViewDelegate
    
    func onHeaderTap(header: HelpHeaderView, sectionIndex: Int, sectionModel: HelpItemSectionModel) {
        setHeaderExpanded(header, sectionIndex: sectionIndex, sectionModel: sectionModel)
    }
    
    private func setHeaderExpanded(header: HelpHeaderView, sectionIndex: Int, sectionModel: HelpItemSectionModel) {
        
        let sectionIndexPath: NSIndexPath = NSIndexPath(forRow: 0, inSection: sectionIndex)
        
        if sectionModel.expanded { // collapse
            tableView.wrapUpdates {[weak self] in
                self?.tableView.deleteRowsAtIndexPaths([sectionIndexPath], withRowAnimation: .Top)
                sectionModel.expanded = false
            }
        } else { // expand
            tableView.wrapUpdates {[weak self] in
                self?.tableView.insertRowsAtIndexPaths([sectionIndexPath], withRowAnimation: .Top)
                sectionModel.expanded = true
            }
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: sectionIndex), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
    }
    
    // MARK: - Filter
    
    
    func textFieldDidChange(textField: UITextField) {
        filter(textField.text ?? "")
    }
    
    private func filter(searchText: String) {
        if searchText.isEmpty {
            filteredModels = sectionModels
        } else {
            filteredModels = sectionModels.collect {model in
                if let range = model.obj.title.range(searchText, caseInsensitive: true) {
                    // on filter collapse all so it's easier for user to see results
                    return HelpItemSectionModel(expanded: false, obj: model.obj, boldRange: range, textHeight: model.textHeight)
                } else {
                    return nil
                }
            }
        }
    }
    
    deinit {
        QL1("Deinit help controller")
    }
}