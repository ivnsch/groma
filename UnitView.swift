//
//  UnitView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 19/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol UnitViewDelegate {
    func onLongPress()
}

@IBDesignable class UnitView: UIView {
    
    @IBInspectable var isBold: Bool = false
    
    @IBOutlet weak var nameLabel: UILabel!
    
    var delegate: UnitViewDelegate?
    
    var markedToDelete: Bool = false
    
    var unit: Providers.Unit? {
        didSet {
            if let unit = unit {
                nameLabel.text = "\(unit.name.isEmpty ? "unit" : unit.name)" // TODO!!!!!!!!!!!!!!!!!! translation for empty unit

                nameLabel.sizeToFit()
                
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    var bgColor: UIColor = Theme.unitsBGColor {
        didSet {
            backgroundColor = bgColor
        }
    }
    
    var fgColor: UIColor = Theme.unitsFGColor {
        didSet {
            nameLabel.textColor = fgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    fileprivate var view: UIView? // The actual view from the XIB
    
    // TODO find a way to not have extra view here (add subview) since this is used in tableview cells.
    fileprivate func xibSetup() {
        let view = Bundle.loadView("UnitView", owner: self)!

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        self.view = view
        
        view.fillSuperview()
        
        isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        
        backgroundColor = UIColor.clear
        view.backgroundColor = UIColor.clear
    }
    
    func mark(toDelete: Bool, animated: Bool) {
        markedToDelete = toDelete
        animIf(animated) {[weak self] in guard let weakSelf = self else {return}
            self?.backgroundColor = toDelete ? UIColor.flatRed : weakSelf.bgColor
        }
    }
    
    func showSelected(selected: Bool, animated: Bool) {
        
        let (bg, fg) = selected ? (Theme.unitsSelectedColor, UIColor.white) : (bgColor, fgColor)
        
        animIf(animated) {[weak self] in
            self?.backgroundColor = bg
            self?.nameLabel.textColor = fg
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if isBold {
            _ = nameLabel.makeBold()
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPress)
    }
    
//    override var intrinsicContentSize: CGSize {
//        let minLabelWidth = max(40, nameLabel.width) // the >= constaint in .xib seems not to work so hardcoded
//        return CGSize(width: minLabelWidth, height: nameLabel.height + 20) // + 20 to add some padding
//    }
    
    func longPress(_ sender: Any) {
        delegate?.onLongPress()
    }
}
