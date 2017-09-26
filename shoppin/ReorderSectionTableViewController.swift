//
//  ReorderSectionTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 05/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol ReorderSectionTableViewControllerDelegate: class {
    func onSectionsUpdated()
    func onSectionSelected(_ section: Section)
    func canRemoveSection(_ section: Section, can: @escaping (Bool) -> Void)
    func onSectionRemoved(_ section: Section)
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Intentionally named setEdit not setEditing because onComplete optional parameter makes setEditing call ambiguous
    func setEdit(_ editing: Bool, animated: Bool, onComplete: VoidFunction? = nil) {
        if let onComplete = onComplete {
            CATransaction.setCompletionBlock(onComplete)
        }
        tableView.setEditing(editing, animated: animated)
        super.setEditing(editing, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setEdit(true, animated: false)
        // cell starts small to blend with the collapsed original tableview and grows to normal size
        setCellHeight(DimensionsManager.defaultCellHeight, animated: true)
        
        tableView.bottomInset = DimensionsManager.listItemsPricesViewHeight + 10 // 10 - show a little empty space between the last item and the prices view
    }
    
    // Animate cell height
    func setCellHeight(_ height: CGFloat, animated: Bool) {
        cellHeight = height
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sectionCell", for: indexPath) as! ReorderSectionCell
        cell.section = sections[(indexPath as NSIndexPath).row]
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let section = sections[(indexPath as NSIndexPath).row]
            
            delegate?.canRemoveSection(section) {[weak self] can in
                if can {
                    tableView.wrapUpdates {[weak self] in
                        self?.sections.remove(at: (indexPath as NSIndexPath).row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                    self?.delegate?.onSectionRemoved(section)
                }
            }
        }
    }

    // Note: status of itels in this list assumed to be .Todo! It's not possible to reorder sections in the other status
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        
        if let status = status {
            let section = sections[(fromIndexPath as NSIndexPath).row]
            sections.remove(at: (fromIndexPath as NSIndexPath).row)
            
            sections.insert(section, at: (toIndexPath as NSIndexPath).row)
            
            sections = sections.enumerated().map{index, section in
                section.updateOrder(ListItemStatusOrder(status: status, order: index))
            }

            fatalError("Outdated - remove this controller") // TODO
//            Prov.sectionProvider.update(sections, remote: true, successHandler{[weak self] in
//                self?.delegate?.onSectionsUpdated()
//            })
            
        } else {
            logger.e("Status not set, can't reorder")
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[(indexPath as NSIndexPath).row]
        delegate?.onSectionSelected(section)
    }
    
    // Updates a section based on identity (uuid). Note that this isn't usable for order update, as updating order requires to update the order field of sections below
    func updateSection(_ section: Section) {
        for i in 0..<sections.count {
            if sections[i].same(section) {
                sections[i] = section
            }
        }
        tableView.reloadData()
    }
    
    func removeSection(_ uuid: String) {
        if let index = getSectionIndex(uuid) {
            removeSection(uuid, index: index)
        } else {
            logger.d("Section to remove not found: \(uuid)")
        }
    }
    
    func getSectionIndex(_ uuid: String) -> Int? {
        for (i, s) in sections.enumerated() {
            if s.uuid == uuid {
                return i
            }
        }
        return nil
    }
    
    fileprivate func removeSection(_ uuid: String, index: Int) {
        tableView.wrapUpdates{[weak self] in
            self?.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .bottom)
            self?.sections.remove(at: index)
        }
    }
    
    deinit {
        logger.v("Deinit")
    }
}
