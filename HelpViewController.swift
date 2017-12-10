//
//  HelpViewController.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

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
    @IBOutlet weak var searchBar: RoundTextField!
    
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!

    fileprivate var sectionModels: [HelpItemSectionModel] = [] {
        didSet {
            filteredModels = sectionModels
        }
    }
    
    fileprivate var filteredModels: [HelpItemSectionModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.addTarget(self, action: #selector(HelpViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        searchBarHeightConstraint.constant = DimensionsManager.searchBarHeight
        
        let recognizer = UITapGestureRecognizer(target: self, action:#selector(HelpViewController.handleTap(_:)))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        
        Prov.helpProvider.helpItems(successHandler {[weak self] helpItems in
            self?.sectionModels = helpItems.map{HelpItemSectionModel(obj: $0)}
        })
    }
    
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return filteredModels.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionModel = filteredModels[section]
        return sectionModel.expanded ? 1 : 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as! HelpCell
        let sectionModel = self.filteredModels[(indexPath as NSIndexPath).section]
        cell.sectionModel = sectionModel
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.loadView("HelpHeaderView", owner: self) as! HelpHeaderView
        let sectionModel = self.filteredModels[section]
        view.sectionModel = sectionModel
        view.delegate = self
        view.sectionIndex = section
        // height now calculated yet so we pass the position of border
        view.addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionModel = self.filteredModels[(indexPath as NSIndexPath).section]
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
    
    func onHeaderTap(_ header: HelpHeaderView, sectionIndex: Int, sectionModel: HelpItemSectionModel) {
        setHeaderExpanded(header, sectionIndex: sectionIndex, sectionModel: sectionModel)
    }
    
    fileprivate func setHeaderExpanded(_ header: HelpHeaderView, sectionIndex: Int, sectionModel: HelpItemSectionModel) {
        
        let sectionIndexPath: IndexPath = IndexPath(row: 0, section: sectionIndex)
        
        if sectionModel.expanded { // collapse
            tableView.wrapUpdates {[weak self] in
                self?.tableView.deleteRows(at: [sectionIndexPath], with: .top)
                sectionModel.expanded = false
            }
        } else { // expand
            tableView.wrapUpdates {[weak self] in
                self?.tableView.insertRows(at: [sectionIndexPath], with: .top)
                sectionModel.expanded = true
            }
            tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: sectionIndex), at: UITableViewScrollPosition.top, animated: true)
        }
    }
    
    // MARK: - Filter
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        filter(textField.text ?? "")
    }
    
    fileprivate func filter(_ searchText: String) {
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
        logger.v("Deinit help controller")
    }
}
