//
//  ListItemCellNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 30/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol ListItemCellDelegateNew: class {
    func onItemSwiped(_ listItem: ListItem)
    func onStartItemSwipe(_ listItem: ListItem)
    func onButtonTwoTap(_ listItem: ListItem)
    func onNoteTap(_ cell: ListItemCellNew, listItem: ListItem)
    func onChangeQuantity(_ listItem: ListItem, delta: Float)
    func onQuantityInput(_ listItem: ListItem, quantity: Float)
    func onDelete(_ listItem: ListItem)
    func onDeepPress(_ listItem: ListItem)
    var isControllerInEditMode: Bool {get}
}

class ListItemCellNew: SwipeableCell, SwipeToIncrementHelperDelegate, QuantityViewDelegate, SwipeToDeleteHelperDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infosLabel: UILabel!
//    @IBOutlet weak var quantityLabel: UILabel!
//    @IBOutlet weak var priceLabel: UILabel! // this was a label below the item's quantity in edit mode howing total price for this item. For now disabled as it overlaps with surrounding +/- and maybe a bit too much information for the user.
    
    @IBOutlet weak var centerVerticallyNameLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteButtonWidthConstraint: NSLayoutConstraint!
    
//    @IBOutlet weak var quantityLabelCenterVerticallyConstraint: NSLayoutConstraint!

    @IBOutlet weak var noteButton: UIButton!
    
    @IBOutlet weak var sectionColorView: UIView!
    
    @IBOutlet weak var quantityView: QuantityView!
//    @IBOutlet weak var plusButton: UIView!
//    @IBOutlet weak var minusButton: UIView!
//    @IBOutlet weak var plusButtonWidthConstraint: NSLayoutConstraint!
//    @IBOutlet weak var minusButtonWidthConstraint: NSLayoutConstraint!
    
//    @IBOutlet weak var undoLabel1: UILabel!
//    @IBOutlet weak var undoLabel2: UILabel!
    
    @IBOutlet weak var bgIconLeft: UIImageView!
    @IBOutlet weak var bgIconRight: UIImageView!
    
    @IBOutlet weak var quantityViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    fileprivate weak var delegate: ListItemCellDelegateNew?
    
    fileprivate var swipeToIncrementHelper: SwipeToIncrementHelper?
    
    fileprivate var strikeLine: UIView?
    
    var startStriked: Bool = false
    
    fileprivate var swipeToDeleteHelper: SwipeToDeleteHelper?

    fileprivate var shownQuantity: Float = 0 {
        didSet {
            if let tableViewListItem = tableViewListItem {

                if tableViewListItem.isInvalidated { return } // quick fix for crash accessing invalid object TODO!!!! try to not store the list item as a variable so we never have invalid object

                quantityView.quantity = shownQuantity
                quantityView.quantityText = String("\(tableViewListItem.product.product.quantityWithMaybeUnitText(quantity: shownQuantity))")
                quantityView.invalidateIntrinsicContentSize()
            }
        }
    }
    
    fileprivate(set) var status: ListItemStatus?
    var mode: ListItemCellMode = .note {
        didSet {
            if mode != oldValue {
                updateModeItemsVisibility(true)
                swipeEnabled = mode == .note
            }
        }
    }

    fileprivate(set) var tableViewListItem: ListItem? {
        didSet {
            if let tableViewListItem = tableViewListItem {
                
                swipeToDeleteHelper?.setOpen(false, animated: false) // recycling

                let listItem = tableViewListItem
                
                nameLabel.text = NSLocalizedString(listItem.product.product.product.item.name, comment: "")
                nameLabel.sizeToFit() // important for strike line
                
                shownQuantity = listItem.quantity
//                shownQuantity = listItem.quantity(status)

                infosLabel.text = infosText(listItem: listItem)
                centerVerticallyNameLabelConstraint.constant = (infosLabel.text ?? "").isEmpty ? 0 : 10

                sectionColorView.backgroundColor = listItem.section.color
                
                updateModeItemsVisibility(false)
                
//                undoLabel1.text = listItem.product.product.product.name
                
                setOpen(tableViewListItem.swiped)
                if tableViewListItem.swiped {
                    backgroundColor = UIColor.clear
                } else {
                    backgroundColor = UIColor.white
                }

                updateStrikeLine()
            }
        }
    }

    fileprivate func infosText(listItem: ListItem) -> String {
        return [listItem.product.product.product.brand, listItem.product.product.baseText].filter {
            !$0.isEmpty
        }.joined(separator: ", ")
    }

    fileprivate func updateStrikeLine() {
    
        if let strikeLine = strikeLine {
            strikeLine.removeFromSuperview()
        }
        
        let strokeWidth: CGFloat = 1
    
        // TODO nameLabel position is not updated yet (centerVerticallyNameLabelConstraint.constant doesn't have effect) where should we call this to not use have to use centerVerticallyNameLabelConstraint.constant? NOTE: Still not displayer correctly in some cells.
//        let line = UIView(frame: CGRect(x: nameLabel.x - 10, y: height / 2 - nameLabel.height / 2 - strokeWidth / 2, width: self.nameLabel.width + 20, height: strokeWidth))
        // NOTE: Using constant cell height because final height not calculated yet here (also not in did add to superview / window, also not after layout calls - only when calling with a delay)
        let contentViewHeight = DimensionsManager.defaultCellHeight
        let line = UIView(frame: CGRect(x: nameLabel.x - 10, y: (contentViewHeight / 2) - centerVerticallyNameLabelConstraint.constant - (strokeWidth / 2), width: self.nameLabel.width + 20, height: strokeWidth))
        line.backgroundColor = UIColor(hexString: "222222")

        // Not sure this is necessary - added a 0.3 delay to add view and with recycling it may make sense to do an extra check to avoid multiple additions
        line.tag = ViewTags.StrikeLine
        if nameLabel.superview?.viewWithTag(ViewTags.StrikeLine) == nil {
            nameLabel.superview?.addSubview(line)
        }

        nameLabel.superview?.bringSubview(toFront: line)
        
        line.layer.anchorPoint = CGPoint(x: 0, y: line.layer.anchorPoint.y)
        line.frame.origin.x = line.frame.origin.x - line.width / 2 // back to original position

        let scaleX: CGFloat = startStriked ? 1 : 0
        line.transform = CGAffineTransform(scaleX: scaleX, y: 1) // Note due to bug in iOS this can't be 0 (it never appears in this case)
        line.isHidden = startStriked ? false : true // without this (when !startStriked) the line appears briefly when the list items controller animates in

        self.strikeLine = line
    }
    
    func update() {
        let tableViewListItem = self.tableViewListItem

        if tableViewListItem?.isInvalidated ?? false { return } // quick fix for crash accessing invalid object TODO!!!! try to not store the list item as a variable so we never have invalid object

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
            updateModeItemsVisibility(mode, status: status, tableViewListItem: tableViewListItem, animated: animated)
        }
    }
    
    fileprivate func updateModeItemsVisibility(_ mode: ListItemCellMode, status: ListItemStatus, tableViewListItem: ListItem, animated: Bool) {

        if tableViewListItem.isInvalidated { return } // quick fix for crash accessing invalid object TODO!!!! try to not store the list item as a variable so we never have invalid object

        let hasNote = !tableViewListItem.note.isEmpty
        let showNote = hasNote && mode == .note
        
        
        func update() {
            switch mode {
                
            case .note:
                noteButton.alpha = showNote ? 1 : 0
                quantityView.setMode(.readonly, animated: false)
                sectionColorView.alpha = 1
                quantityViewTrailingConstraint.constant = DimensionsManager.leftRightPaddingConstraint
                deleteButton.isHidden = true
                bgIconLeft.isHidden = false
                bgIconRight.isHidden = false
                contentView.backgroundColor = Theme.lighterGreen
                
            case .increment:
                noteButton.alpha = 0
                quantityView.setMode(.edit, animated: false)
                sectionColorView.alpha = 0
                quantityViewTrailingConstraint.constant = 0
                deleteButton.isHidden = false
                bgIconLeft.isHidden = true
                bgIconRight.isHidden = true
                contentView.backgroundColor = Theme.deleteRed
            }
            
            layoutIfNeeded()
        }
        
        animIf(animated, Theme.defaultAnimDuration, { 
            update()
        }) {[weak self] in
            self?.noteButtonWidthConstraint.constant = showNote ? 61 : 0
        }
    }
    
    fileprivate func showPrice(_ tableViewListItem: TableViewListItem, status: ListItemStatus, mode: ListItemCellMode, animated: Bool, animDelay: TimeInterval) {
        let price = tableViewListItem.listItem.totalPrice()
        let hasPrice = price > 0
        let showPrice = hasPrice && mode == .increment
        if showPrice {
//            priceLabel.text = price.toLocalCurrencyString()
        }
        
        func updateConstraint() {
//            quantityLabelCenterVerticallyConstraint.constant = showPrice ? 10 : 0
        }
        
        func updateAlpha() {
//            priceLabel.alpha = showPrice ? 1 : 0
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
        
//        quantityLabelCenterVerticallyConstraint.constant = 0
//        priceLabel.alpha = 0
        
//        undoLabel2.text = trans("generic_undo")
        
        selectionStyle = UITableViewCellSelectionStyle.none

        
        //        // block tapping the cell behind the +/- buttons, otherwise it's easy to open the edit listitem view by mistake
        //        let tapRecognizer = UITapGestureRecognizer(target: self, action: "onTapPlusMinusContainer:")
        //        minusButton.addGestureRecognizer(tapRecognizer)
        
        swipeToDeleteHelper = SwipeToDeleteHelper(parentView: self, button: myContentView, leftLayoutConstraint: contentViewLeftConstraint, rightLayoutConstraint: contentViewRightConstraint, cancelTouches: false)
        swipeToDeleteHelper?.delegate = self
        
        swipeToIncrementHelper = SwipeToIncrementHelper(view: myContentView)
        swipeToIncrementHelper?.delegate = self
        
        let scaleStart = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
        bgIconLeft.transform = scaleStart
        bgIconRight.transform = scaleStart
        
        quantityView.delegate = self
        
        quantityViewTrailingConstraint.constant = DimensionsManager.leftRightPaddingConstraint
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPress.delegate = self
        addGestureRecognizer(longPress)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        addGestureRecognizer(tap)
        tap.require(toFail: longPress)

        let deepTouchRecognizer = DeepPressGestureRecognizer()
        deepTouchRecognizer.delegate = self
        addGestureRecognizer(deepTouchRecognizer)
        deepTouchRecognizer.require(toFail: longPress)
        deepTouchRecognizer.onDeepPress = { [weak self] in
            longPress.cancel()
            if let listItem = self?.tableViewListItem {
                self?.delegate?.onDeepPress(listItem)
                return
            }
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: quantityView) ?? false {
            return false
        }

        if gestureRecognizer is UILongPressGestureRecognizer {
            print("long press should receive?")
        }

        return true
    }
    
    // MARK: -
    
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
        guard let listItem = tableViewListItem else {logger.e("No list item"); return}
        
        delegate?.onItemSwiped(listItem)
    }
    
    override func onSwipe(delta: CGFloat, panningRight: Bool) {
        let absDelta = abs(delta)
        
        let offset = width / 12 // when it starts growing
        
        let deltaMinusPart = absDelta - offset
        
        let fullScaleDelta = width / 5 // distance to when it achieves full scale
        let percentage = min(1, deltaMinusPart / fullScaleDelta)
        
        if absDelta > offset {
            
            let scale = CGAffineTransform(scaleX: percentage, y: percentage)
            
            bgIconLeft.transform = scale
            bgIconRight.transform = scale
            
            bgIconLeft.isHidden = delta > 0
            bgIconRight.isHidden = !bgIconLeft.isHidden
            
        }
        
        
        let linePercentage = min(1, absDelta / fullScaleDelta)
        let finalLinePercentage = startStriked ? 1 - linePercentage : linePercentage // invert if startStriked
        strikeLine?.isHidden = false
        strikeLine?.transform = CGAffineTransform(scaleX: finalLinePercentage, y: 1)
        
    }
    
    override func onShowAllButtons(delta: CGFloat) {
        UIView.animate(withDuration: 0.2) {
            // one is hidden so we can just scale up both
            let scale = CGAffineTransform(scaleX: 1, y: 1)
            self.bgIconLeft.transform = scale
            self.bgIconRight.transform = scale
            

            if self.startStriked {
                self.strikeLine?.transform = CGAffineTransform(scaleX: 0.00001, y: 1)
            } else {
                self.strikeLine?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            
        }
    }
    
    override func onResetConstraints(delta: CGFloat) {
        UIView.animate(withDuration: 0.2) {
            // one is hidden so we can just scale up both
            let scale = CGAffineTransform(scaleX: 0.00001, y: 0.00001)
            self.bgIconLeft.transform = scale
            self.bgIconRight.transform = scale
            
            if self.startStriked {
                self.strikeLine?.transform = CGAffineTransform(scaleX: 1, y: 1)
            } else {
                self.strikeLine?.transform = CGAffineTransform(scaleX: 0.00001, y: 1)
            }
        }
    }
    
    // MARK: - SwipeToIncrementHelperDelegate
    
    func currentQuantity() -> Float {
        return shownQuantity
    }
    
    func onQuantityUpdated(_ quantity: Float) {
        
        if let tableViewListItem = tableViewListItem {
            let delta = shownQuantity - tableViewListItem.quantity
            shownQuantity = quantity
            
            quantityView.showDelta(delta)
        } else {
            logger.w("no tableViewListItem")
        }
    }
    
    func onFinishSwipe() {
        
        if let tableViewListItem = tableViewListItem {
            let delta = shownQuantity - tableViewListItem.quantity
            delegate?.onChangeQuantity(tableViewListItem, delta: delta)
        } else {
            logger.w("Warn: ListItemCell.onStartItemSwipe: no tableViewListItem")
        }
    }
    
    var swipeToIncrementEnabled: Bool {
        if mode == .increment {
            let isOpen = swipeToDeleteHelper?.isOpen ?? false
            return !isOpen
        } else {
            return false
        }
    }
    
    // MARK: - SwipeToDeleteHelperDelegate
    
    func onOpen(_ open: Bool) {
        if open {
            if let tableViewListItem = tableViewListItem {
                delegate?.onDelete(tableViewListItem)
            } else {
                logger.w("No listItem")
            }
        }
    }
    
    var isSwipeToDeleteEnabled: Bool {
        return shownQuantity == 0
            && (mode == .increment && !isEditing) // show in increment mode but not when the cell is in edit mode (i.e. only on long-tap edit). The reason is that during edit mode we have reorder control and swipe to delete looks weird with it as it appears on the left side of the reorder control.
    }
    
    // MARK: - Touch
    
    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        guard !isEditing else { return }
        
        switch sender.state {
        case .began: mode = mode == .increment ? .note : .increment
        default: break
        }
    }
    
    @objc func onTap(_ sender: UITapGestureRecognizer) {
        // Cancel edit mode for cells that were put in edit mode via long press
        guard let delegate = delegate else {logger.e("No delegate"); return}
        if mode == .increment && !delegate.isControllerInEditMode {
            mode = .note
        }
    }


    // MARK: - QuantityViewDelegate
    
    func onRequestUpdateQuantity(_ delta: Float) {
        
        guard let tableViewListItem = tableViewListItem else {logger.e("Illegal state: No list item"); return}
        
        shownQuantity = shownQuantity + delta // increment in advance // TODO!!!!!!!!!!!!!!!! test if this always works as intented
        delegate?.onChangeQuantity(tableViewListItem, delta: delta)
    }
    
    func onQuantityInput(_ quantity: Float) {
        
        guard let tableViewListItem = tableViewListItem else {logger.e("Illegal state: No list item"); return}
        
        delegate?.onQuantityInput(tableViewListItem, quantity: quantity)
    }
}

