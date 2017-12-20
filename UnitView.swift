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

    @IBOutlet weak var imageViewContainer: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    var delegate: UnitViewDelegate?
    
    var markedToDelete: Bool = false
    
    var unit: Providers.Unit? {
        didSet {
            if let unit = unit {
                nameLabel.text = "\(unit.name.isEmpty ? trans("unit_unit") : unit.name)"

                nameLabel.sizeToFit()

                initialsLabel.isHidden = true

                imageView.image = Theme.unitImage(unitId: unit.id)

                if unit.id == .custom {
                    initialsLabel.text = String(unit.name.prefix(2).uppercased())
                    initialsLabel.isHidden = false
                }

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
            self?.imageViewContainer.backgroundColor = toDelete ? UIColor.flatRed : Theme.grey
        }
    }
    
    func showSelected(selected: Bool, animated: Bool) {
//        animIf(animated) {[weak self] in
            imageViewContainer.backgroundColor = selected ? Theme.green : Theme.grey
//        }
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
    
    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            delegate?.onLongPress()
        }
    }
}
