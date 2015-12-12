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
    
    var cellBgColor: UIColor?
    var selectedCellBgColor: UIColor?
    var textColor: UIColor?
    
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
        setCellHeight(50, animated: true)
    }
    
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
        cell.contentView.backgroundColor = cellBgColor ?? UIColor.whiteColor()
        cell.backgroundColor = cellBgColor ?? UIColor.whiteColor()
        cell.nameLabel.textColor = textColor ?? UIColor.blackColor()
        
        let bgColorView = UIView(frame: cell.frame)
        let finalSelectedCellBgColor = selectedCellBgColor ?? UIColor.redColor()
        bgColorView.backgroundColor = finalSelectedCellBgColor
        cell.nameLabel.highlightedTextColor = UIColor(contrastingBlackOrWhiteColorOn: finalSelectedCellBgColor, isFlat: true)

        cell.selectedBackgroundView = bgColorView
        
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

    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        let section = sections[fromIndexPath.row]
        sections.removeAtIndex(fromIndexPath.row)
        
        sections.insert(section, atIndex: toIndexPath.row)
        
        sections = sections.enumerate().map{index, section in
            section.copy(order: index)
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
}
