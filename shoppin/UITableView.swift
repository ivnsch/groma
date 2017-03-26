//
//  UITableView.swift
//  shoppin
//
//  Created by ischuetz on 01/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs

extension UITableView {
    
    var inset: UIEdgeInsets {
        set {
            self.contentInset = newValue
            
            //TODO do we need this
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
        get {
            return self.contentInset
        }
    }
    
    var topOffset: CGFloat {
        set {
            self.contentOffset = CGPoint(x: contentOffset.x, y: newValue)
        }
        get {
            return self.contentOffset.y
        }
    }
    
    var topInset: CGFloat {
        set {
            contentInset = UIEdgeInsets(top: newValue, left: contentInset.left, bottom: contentInset.bottom, right: contentInset.right)
        }
        get {
            return contentInset.top
        }
    }

    var bottomInset: CGFloat {
        set {
            contentInset = UIEdgeInsets(top: contentInset.top, left: contentInset.left, bottom: newValue, right: contentInset.right)
        }
        get {
            return contentInset.bottom
        }
    }
    
    var visibleIndexPaths: [IndexPath] {
        return indexPathsForVisibleRows ?? []
    }

    // src: http://stackoverflow.com/a/31029960/930450
    var visibleSections: [Int] {
        // Note: We can't just use indexPathsForVisibleRows, since it won't return index paths for empty sections.
        var visibleSectionIndexes = [Int]()
        
        for i in 0..<numberOfSections {
            var headerRect: CGRect?
            // In plain style, the section headers are floating on the top, so the section header is visible if any part of the section's rect is still visible.
            // In grouped style, the section headers are not floating, so the section header is only visible if it's actualy rect is visible.
            if (self.style == .plain) {
                headerRect = rect(forSection: i)
            } else {
                headerRect = rectForHeader(inSection: i)
            }
            if headerRect != nil {
                // The "visible part" of the tableView is based on the content offset and the tableView's size.
                let visiblePartOfTableView: CGRect = CGRect(x: contentOffset.x, y: contentOffset.y, width: bounds.size.width, height: bounds.size.height)
                if (visiblePartOfTableView.intersects(headerRect!)) {
                    visibleSectionIndexes.append(i)
                }
            }
        }
        return visibleSectionIndexes
    }
    
    var visibleSectionViews: [UITableViewHeaderFooterView] {
        var visibleSects = [UITableViewHeaderFooterView]()
        for sectionIndex in visibleSections {
            if let sectionHeader = headerView(forSection: sectionIndex) {
                visibleSects.append(sectionHeader)
            }
        }
        
        return visibleSects
    }
    
    
    func applyToVisibleSections(f: (Int, UIView) -> Void) {
        for visibleSectionIndex in visibleSections {
            if let headerView = headerView(forSection: visibleSectionIndex) {
                f(visibleSectionIndex, headerView)
            }
        }
    }
    
    func applyToVisibleRows(f: (IndexPath, UIView) -> Void) {
        for visibleIndexPath in visibleIndexPaths {
            if let headerView = cellForRow(at: visibleIndexPath) {
                f(visibleIndexPath, headerView)
            }
        }
    }
    
    func absoluteRow(_ indexPath: IndexPath) -> Int {
        var absRow = (indexPath as NSIndexPath).row
        for section in 0..<(indexPath as NSIndexPath).section {
            absRow += self.numberOfRows(inSection: section)
        }
        return absRow
    }
    
    func wrapUpdates(_ function: VoidFunction) {
        self.beginUpdates()
        function()
        self.endUpdates()
    }
    
    func wrapAnimationAndUpdates(_ function: VoidFunction, onComplete: @escaping VoidFunction) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            onComplete()
        }
        self.beginUpdates()
        function()
        self.endUpdates()
        CATransaction.commit()
    }
    
    func addRow(indexPath: IndexPath, isNewSection: Bool) {
        
        beginUpdates()
        if isNewSection {
            insertSections([indexPath.section], with: .top)
        }
        insertRows(at: [IndexPath(row: indexPath.row, section: indexPath.section)], with: .top)
        endUpdates()
    }
    
    func updateRow(indexPath: IndexPath) {
        reloadRows(at: [indexPath], with: .none)
    }
    
    func deleteSection(index: Int) {
        deleteSections(IndexSet([index]), with: .top)
    }
}
