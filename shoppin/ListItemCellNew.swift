//
//  ListItemCellNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 30/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

protocol ListItemCellDelegateNew: class {
    func onItemSwiped(_ listItem: ListItem)
    func onStartItemSwipe(_ listItem: ListItem)
    func onButtonTwoTap(_ listItem: ListItem)
    func onNoteTap(_ cell: ListItemCellNew, listItem: ListItem)
    func onMinusTap(_ listItem: ListItem)
    func onPlusTap(_ listItem: ListItem)
    func onPanQuantityUpdate(_ tableViewListItem: ListItem, newQuantity: Int)
}

class ListItemCellNew: SwipeableCell, SwipeToIncrementHelperDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel! // this was a label below the item's quantity in edit mode howing total price for this item. For now disabled as it overlaps with surrounding +/- and maybe a bit too much information for the user.
    
    @IBOutlet weak var centerVerticallyNameLabelConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var quantityLabelCenterVerticallyConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var noteButton: UIButton!
    
    @IBOutlet weak var sectionColorView: UIView!
    
    @IBOutlet weak var plusButton: UIView!
    @IBOutlet weak var minusButton: UIView!
    @IBOutlet weak var plusButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var minusButtonWidthConstraint: NSLayoutConstraint!
    
//    @IBOutlet weak var undoLabel1: UILabel!
//    @IBOutlet weak var undoLabel2: UILabel!
    
    @IBOutlet weak var bgIconLeft: UIImageView!
    @IBOutlet weak var bgIconRight: UIImageView!
    
    @IBOutlet weak var minusTrailingConstraint: NSLayoutConstraint!
    
    fileprivate weak var delegate: ListItemCellDelegateNew?
    
    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    fileprivate var shownQuantity: Int = 0 {
        didSet {
            if let tableViewListItem = tableViewListItem {
                quantityLabel.text = String("\(shownQuantity) \(tableViewListItem.product.product.unitText)")
            }
        }
    }
    
    fileprivate(set) var status: ListItemStatus?
    var mode: ListItemCellMode = .note {
        didSet {
            updateModeItemsVisibility(true)
            swipeToIncrementHelper?.enabled = mode == .increment
        }
    }

    fileprivate(set) var tableViewListItem: ListItem? {
        didSet {
            if let tableViewListItem = tableViewListItem, let status = status {
                
                let listItem = tableViewListItem
                
                nameLabel.text = NSLocalizedString(listItem.product.product.product.name, comment: "")
                shownQuantity = listItem.quantity
//                shownQuantity = listItem.quantity(status)
                
                centerVerticallyNameLabelConstraint.constant = listItem.product.product.product.brand.isEmpty ? 0 : 10
                brandLabel.text = listItem.product.product.product.brand
                
                sectionColorView.backgroundColor = listItem.section.color
                
                updateModeItemsVisibility(false)
                
//                undoLabel1.text = listItem.product.product.product.name
                
                setOpen(tableViewListItem.swiped)
                if tableViewListItem.swiped {
                    backgroundColor = UIColor.clear
                } else {
                    backgroundColor = UIColor.white
                }
            }
        }
    }
    
    func update() {
        let tableViewListItem = self.tableViewListItem
        self.tableViewListItem = tableViewListItem
    }
    
    func setup(_ status: ListItemStatus, mode: ListItemCellMode, tableViewListItem: ListItem, delegate: ListItemCellDelegateNew) {
        self.status = status
        self.mode = mode
        
        self.tableViewListItem = tableViewListItem
        
        self.delegate = delegate
    }
    
    fileprivate func updateModeItemsVisibility(_ animated: Bool) {
        if let tableViewListItem = tableViewListItem, let status = status {
            updateModeItemsVisibility(mode, status: status, tableViewListItem: tableViewListItem, animated: true)
        }
    }
    
    fileprivate func updateModeItemsVisibility(_ mode: ListItemCellMode, status: ListItemStatus, tableViewListItem: ListItem, animated: Bool) {
        
        let hasNote = !tableViewListItem.note.isEmpty
        let showNote = hasNote && mode == .note
        
        // Hide these labels during edit, for reordering (otherwise they stay visible while cell becomes semitransparent). We don't use undo in edit so it's ok to do this fix here. Otherwise private api like described here http://stackoverflow.com/a/10854018/930450, to get events when cell starts and ends moving works too (tested it on iOS 9). Prefer to do it here to avoid using private api.
        let isEdit = mode == .increment
//        undoLabel1.isHidden = isEdit
//        undoLabel2.isHidden = isEdit
        
        let (itemsDelay, priceDelay): (TimeInterval, TimeInterval) = {
            if animated {
                return mode == .note ? (0.1, 0) : (0, 0.3) // for price a different delay to make it animate after/before the other elements (looks better imo)
            } else {
                return (0, 0)
            }
        }()
        
        func update() {
            layoutIfNeeded()
            switch mode {
            case .note:
                noteButton.alpha = showNote ? 1 : 0
                plusButton.alpha = 0
                minusButton.alpha = 0
                sectionColorView.alpha = 1
            case .increment:
                noteButton.alpha = 0
                plusButton.alpha = 1
                minusButton.alpha = 1
                sectionColorView.alpha = 0
            }
        }
        
        if animated {
            
            let constant: CGFloat = {
                switch mode {
                case .note: return 0
                case .increment: return 41
                }
            }()
            
            let minusConstant: CGFloat = {
                switch mode {
                case .note: return DimensionsManager.leftRightPaddingConstraint
                case .increment: return 0
                }
            }()
            
            delay(itemsDelay) {[weak self] in
                self?.plusButtonWidthConstraint.constant = constant
                self?.minusButtonWidthConstraint.constant = constant
                self?.minusTrailingConstraint.constant = minusConstant
                UIView.animate(withDuration: 0.2, animations: {
                    update()
                })
            }
            
        } else {
            update()
        }
        
        //        showPrice(tableViewListItem, status: status, mode: mode, animated: animated, animDelay: priceDelay)
    }
    
    fileprivate func showPrice(_ tableViewListItem: TableViewListItem, status: ListItemStatus, mode: ListItemCellMode, animated: Bool, animDelay: TimeInterval) {
        let price = tableViewListItem.listItem.totalPrice(status)
        let hasPrice = price > 0
        let showPrice = hasPrice && mode == .increment
        if showPrice {
            priceLabel.text = price.toLocalCurrencyString()
        }
        
        func updateConstraint() {
            quantityLabelCenterVerticallyConstraint.constant = showPrice ? 10 : 0
        }
        
        func updateAlpha() {
            priceLabel.alpha = showPrice ? 1 : 0
        }
        
        if animated {
            delay(animDelay) {[weak self] in
                updateConstraint()
                UIView.animate(withDuration: 0.1, animations: {
                    self?.layoutIfNeeded()
                    updateAlpha()
                })
            }
        } else {
            updateConstraint()
            updateAlpha()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        quantityLabelCenterVerticallyConstraint.constant = 0
        priceLabel.alpha = 0
        
//        undoLabel2.text = trans("generic_undo")
        
        selectionStyle = UITableViewCellSelectionStyle.none

        
        //        // block tapping the cell behind the +/- buttons, otherwise it's easy to open the edit listitem view by mistake
        //        let tapRecognizer = UITapGestureRecognizer(target: self, action: "onTapPlusMinusContainer:")
        //        minusButton.addGestureRecognizer(tapRecognizer)
        
        swipeToIncrementHelper = SwipeToIncrementHelper(view: myContentView)
        swipeToIncrementHelper?.delegate = self
        
        let scaleStart = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
        bgIconLeft.transform = scaleStart
        bgIconRight.transform = scaleStart
    }
    
    func onTapPlusMinusContainer(_ recognizer: UITapGestureRecognizer) {
        // do nothing
    }
    
    @IBAction func onNoteTap(_ sender: UIButton) {
        if let tableViewListItem = tableViewListItem{
            delegate?.onNoteTap(self, listItem: tableViewListItem)
        } else {
            print("Warn: ListItemCell.onNoteTap: no tableViewListItem")
        }
    }
    
    // TODO when we tap on minus while the item is 0, the item is cleared - this was not intentional but turns to be the desired behaviour. Review why it's cleared
    // TODO! related with above - review that due to the way we manage the quantity of the items (item is shown when todo/done/stash quantity > 0) we don't keep listitems in the database which are never shown and thus can't be deleted.
    @IBAction func onMinusTap(_ sender: UIButton) {
        if let tableViewListItem = tableViewListItem{
            delegate?.onMinusTap(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onMinusTap: no tableViewListItem")
        }
    }
    
    @IBAction func onPlusTap(_ sender: UIButton) {
        if let tableViewListItem = tableViewListItem{
            delegate?.onPlusTap(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onPlusTap: no tableViewListItem")
        }
    }
    
    override func onStartItemSwipe() {
        if let tableViewListItem = tableViewListItem{
            delegate?.onStartItemSwipe(tableViewListItem)
        } else {
            print("Warn: ListItemCell.onStartItemSwipe: no tableViewListItem")
        }
    }
    
//    override func onButtonTwoTap() {
//        if let tableViewListItem = tableViewListItem{
//            delegate?.onButtonTwoTap(tableViewListItem)
//        } else {
//            print("Warn: ListItemCell.onButtonTwoTap: no tableViewListItem")
//        }
//    }
    
    override func onItemSwiped() {
        guard let listItem = tableViewListItem else {QL4("No list item"); return}
        
        delegate?.onItemSwiped(listItem)
    }
    
    override func onSwipe(delta: CGFloat, panningRight: Bool) {
        let absDelta = abs(delta)
        
        let offset = width / 12 // when it starts growing
        
        if absDelta > offset {
            
            let deltaMinusPart = absDelta - offset
            
            let fullScaleDelta = width / 5 // distance to when it achieves full scale
            let percentage = min(1, deltaMinusPart / fullScaleDelta)
            
            let scale = CGAffineTransform(scaleX: percentage, y: percentage)
            
            bgIconLeft.transform = scale
            bgIconRight.transform = scale
            
            bgIconLeft.isHidden = delta > 0
            bgIconRight.isHidden = !bgIconLeft.isHidden
        }
    }
    
    override func onShowAllButtons(delta: CGFloat) {
        UIView.animate(withDuration: 0.2) {
            // one is hidden so we can just scale up both
            let scale = CGAffineTransform(scaleX: 1, y: 1)
            self.bgIconLeft.transform = scale
            self.bgIconRight.transform = scale
        }
    }
    
    override func onResetConstraints(delta: CGFloat) {
        UIView.animate(withDuration: 0.2) {
            // one is hidden so we can just scale up both
            let scale = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
            self.bgIconLeft.transform = scale
            self.bgIconRight.transform = scale
        }
    }
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Int {
        return shownQuantity
    }
    
    func onQuantityUpdated(_ quantity: Int) {
        shownQuantity = quantity
    }
    
    func onFinishSwipe() {
        if let tableViewListItem = tableViewListItem {
            delegate?.onPanQuantityUpdate(tableViewListItem, newQuantity: shownQuantity)
        } else {
            QL3("Warn: ListItemCell.onStartItemSwipe: no tableViewListItem")
        }
    }
}
