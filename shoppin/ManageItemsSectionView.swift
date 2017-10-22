//
//  ManageItemsSectionView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 15/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers


protocol ManageItemsSectionViewDelegate: class {
    func onHeaderTap(section: Int, view: ManageItemsSectionView)
    func onHeaderLongTap(section: Int, view: ManageItemsSectionView)
    func onDeleteSectionTap(section: Int, view: ManageItemsSectionView)
}

class ManageItemsSectionView: UITableViewHeaderFooterView, CellUncovererDelegate {
    
    @IBOutlet weak var categoryColorView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var categoryNameLabel: UILabel!

    // Swipe to delete
    @IBOutlet weak var myContentView: UIView!
    @IBOutlet weak var leftLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteButton: UIButton!
    fileprivate var cellUncoverer: CellUncoverer?

    fileprivate var categoryColor: UIColor?
    
    weak var delegate: ManageItemsSectionViewDelegate!

    var sectionIndex: Int? // NOTE: has to be udpated when a section is deleted
    
    func config(item: Item, editing: Bool) {
        
        nameLabel.text = item.name
        categoryNameLabel.text = item.category.name
        
        updateCategoryColorVisibility(editing: editing, animated: false)
        
        categoryColor = item.category.color
        
        // height now calculated yet so we pass the position of border
        addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.ingredientsCellHeight)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        myContentView.addGestureRecognizer(longPress)
    }

    fileprivate func updateCategoryColorVisibility(editing: Bool, animated: Bool) {
        guard let categoryColor = categoryColor else {return}
        
        animIf(animated) {[weak self] in guard let weakSelf = self else {return}
            weakSelf.categoryColorView.backgroundColor = editing ? UIColor.clear : categoryColor
        }
    }
    
    func setEditing(_ editing: Bool, animated: Bool) {
        updateCategoryColorVisibility(editing: editing, animated: animated)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = UIColor(hexString: "FF3B30")
        
        configDelete()
    }
    
    fileprivate func configDelete() {
        cellUncoverer = CellUncoverer(parentView: self, button: myContentView, leftLayoutConstraint: leftLayoutConstraint)
        cellUncoverer?.stashViewWidth = 76
        cellUncoverer?.allowOpen = true
        cellUncoverer?.delegate = self
    }
    
    var open: Bool = false {
        didSet {
            if !open {
                cellUncoverer?.setOpen(false, animated: true)
            }
        }
    }
    
    @IBAction func onDeleteButtonTap(_ sender: UIButton) {
        if let sectionIndex = sectionIndex {
            delegate?.onDeleteSectionTap(section: sectionIndex, view: self)
        } else {
            logger.e("No headerIndex or group")
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let sectionIndex = sectionIndex {
            delegate?.onHeaderTap(section: sectionIndex, view: self)
        } else {
            logger.e("No headerIndex or group")
        }
    }
    
    @objc func longPress(_ sender: Any) {
        if let sectionIndex = sectionIndex {
            delegate?.onHeaderLongTap(section: sectionIndex, view: self)
        } else {
            logger.e("No headerIndex or group")
        }
        
    }
    
    // MARK: - CellUncovererDelegate
    
    func onOpen(_ open: Bool) {
        self.open = open
    }
}
