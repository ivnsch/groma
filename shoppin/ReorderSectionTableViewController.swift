//
//  ReorderSectionTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ReorderSectionTableViewControllerDelegate {
    func onSectionsUpdated()
    func onSectionSelected(section: Section)
}

class ReorderSectionTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sections: [Section] = []
    
    var onViewDidLoad: VoidFunction?
    
    var cellHeight: CGFloat = 30
    
    var delegate: ReorderSectionTableViewControllerDelegate?
    
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
        setCellHeight(50, animated: true)
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

    /*
    // TODO
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    // Note: status of itels in this list assumed to be .Todo! It's not possible to reorder sections in the other status
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        let section = sections[fromIndexPath.row]
        sections.removeAtIndex(fromIndexPath.row)
        
        sections.insert(section, atIndex: toIndexPath.row)
        
        sections = sections.enumerate().map{index, section in
            section.copy(todoOrder: index)
        }

        Providers.sectionProvider.update(sections, remote: true, successHandler{[weak self] in
            self?.delegate?.onSectionsUpdated()
        })
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
}
