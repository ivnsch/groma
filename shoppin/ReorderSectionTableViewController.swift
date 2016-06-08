//
//  ReorderSectionTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol ReorderSectionTableViewControllerDelegate: class {
    func onSectionsUpdated()
    func onSectionSelected(section: Section)
    func canRemoveSection(section: Section, can: Bool -> Void)
    func onSectionRemoved(section: Section)
}

class ReorderSectionTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sections: [Section] = []
    
    var onViewDidLoad: VoidFunction?
    
    var cellHeight: CGFloat = DimensionsManager.listItemsHeaderHeight
    
    weak var delegate: ReorderSectionTableViewControllerDelegate?
    
    var status: ListItemStatus?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelectionDuringEditing = true
        
        onViewDidLoad?()
    }

    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // Intentionally named setEdit not setEditing because onComplete optional parameter makes setEditing call ambiguous
    func setEdit(editing: Bool, animated: Bool, onComplete: VoidFunction? = nil) {
        if let onComplete = onComplete {
            CATransaction.setCompletionBlock(onComplete)
        }
        tableView.setEditing(editing, animated: animated)
        super.setEditing(editing, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        setEdit(true, animated: false)
        // cell starts small to blend with the collapsed original tableview and grows to normal size
        setCellHeight(DimensionsManager.defaultCellHeight, animated: true)
        
        tableView.bottomInset = DimensionsManager.listItemsPricesViewHeight + 10 // 10 - show a little empty space between the last item and the prices view
    }
    
    // Animate cell height
    func setCellHeight(height: CGFloat, animated: Bool) {
        cellHeight = height
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sectionCell", forIndexPath: indexPath) as! ReorderSectionCell
        cell.section = sections[indexPath.row]
        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            let section = sections[indexPath.row]
            
            delegate?.canRemoveSection(section) {[weak self] can in
                if can {
                    tableView.wrapUpdates {[weak self] in
                        self?.sections.removeAtIndex(indexPath.row)
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                    self?.delegate?.onSectionRemoved(section)
                }
            }
        }
    }

    // Note: status of itels in this list assumed to be .Todo! It's not possible to reorder sections in the other status
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        if let status = status {
            let section = sections[fromIndexPath.row]
            sections.removeAtIndex(fromIndexPath.row)
            
            sections.insert(section, atIndex: toIndexPath.row)
            
            sections = sections.enumerate().map{index, section in
                section.updateOrder(ListItemStatusOrder(status: status, order: index))
            }
            
            Providers.sectionProvider.update(sections, remote: true, successHandler{[weak self] in
                self?.delegate?.onSectionsUpdated()
            })
            
        } else {
            QL4("Status not set, can't reorder")
        }
    }

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = sections[indexPath.row]
        delegate?.onSectionSelected(section)
    }
    
    // Updates a section based on identity (uuid). Note that this isn't usable for order update, as updating order requires to update the order field of sections below
    func updateSection(section: Section) {
        for i in 0..<sections.count {
            if sections[i].same(section) {
                sections[i] = section
            }
        }
        tableView.reloadData()
    }
    
    func removeSection(uuid: String) {
        if let index = getSectionIndex(uuid) {
            removeSection(uuid, index: index)
        } else {
            QL2("Section to remove not found: \(uuid)")
        }
    }
    
    func getSectionIndex(uuid: String) -> Int? {
        for (i, s) in sections.enumerate() {
            if s.uuid == uuid {
                return i
            }
        }
        return nil
    }
    
    private func removeSection(uuid: String, index: Int) {
        tableView.wrapUpdates{[weak self] in
            self?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Bottom)
            self?.sections.removeAtIndex(index)
        }
    }
}
