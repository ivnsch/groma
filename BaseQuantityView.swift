//
//  BaseQuantityView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 22/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol BaseQuantityViewDelegate {
    func onLongPress()
}

@IBDesignable class BaseQuantityView: UIView {
    
    @IBInspectable var isBold: Bool = false
    
    @IBOutlet weak var baseQuantityLabel: UILabel!
    
    var delegate: BaseQuantityViewDelegate?
    
    var markedToDelete: Bool = false
    
    var base: BaseQuantity? {
        didSet {
            if let base = base {
                baseQuantityLabel.text = "\(base.stringVal.isEmpty ? "" : base.stringVal)" // TODO!!!!!!!!!!!!!!!!!! translation for empty unit
                
                baseQuantityLabel.sizeToFit()
                
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    var bgColor: UIColor = UIColor.white {
        didSet {
            backgroundColor = bgColor
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
        let view = Bundle.loadView("BaseQuantityView", owner: self)!
        
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
        
        let (bg, fg) = selected ? (Theme.unitsSelectedColor, UIColor.white) : (bgColor, UIColor.black)
        
        animIf(animated) {[weak self] in
            self?.backgroundColor = bg
            self?.baseQuantityLabel.textColor = fg
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if isBold {
            _ = baseQuantityLabel.makeBold()
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPress)
    }
    
    //    override var intrinsicContentSize: CGSize {
    //        let minLabelWidth = max(40, baseQuantityLabel.width) // the >= constaint in .xib seems not to work so hardcoded
    //        return CGSize(width: minLabelWidth, height: baseQuantityLabel.height + 20) // + 20 to add some padding
    //    }
    
    func longPress(_ sender: Any) {
        delegate?.onLongPress()
    }
}
