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
    @IBOutlet weak var nameLabel: UILabel!
    
    var delegate: UnitViewDelegate?
    
    var markedToDelete: Bool = false
    
    var unit: Providers.Unit? {
        didSet {
            if let unit = unit {
                nameLabel.text = "\(unit.name.isEmpty ? trans("unit_unit") : unit.name)"

                nameLabel.sizeToFit()

                let image: UIImage = {
                    switch unit.id {
                    case .none: return #imageLiteral(resourceName: "can")
                    case .g: return #imageLiteral(resourceName: "g")
                    case .kg: return #imageLiteral(resourceName: "kg")
                    case .ounce: return #imageLiteral(resourceName: "oz")
                    case .pack: return #imageLiteral(resourceName: "pack")
                    case .cup: return #imageLiteral(resourceName: "cup")
                    case .teaspoon: return #imageLiteral(resourceName: "tbsp")
                    case .spoon: return #imageLiteral(resourceName: "tbsp")
                    case .pinch: return #imageLiteral(resourceName: "pinch")
                    case .pound: return #imageLiteral(resourceName: "lb")
                    case .liter: return #imageLiteral(resourceName: "litre")
                    case .milliliter: return #imageLiteral(resourceName: "ml")
                    case .drop: return #imageLiteral(resourceName: "drop")
                    case .shot: return #imageLiteral(resourceName: "shot")
                    case .clove: return #imageLiteral(resourceName: "shot")
                    case .can: return#imageLiteral(resourceName: "can")
                    case .custom: return#imageLiteral(resourceName: "can")
                    case .pint: return #imageLiteral(resourceName: "pint")
                    case .gin: return #imageLiteral(resourceName: "gin")
                    case .floz: return #imageLiteral(resourceName: "floz")
                    case .dash: return #imageLiteral(resourceName: "dash")
                    case .wgf: return #imageLiteral(resourceName: "wgf")
                    case .dram: return #imageLiteral(resourceName: "dram")
                    case .lb: return #imageLiteral(resourceName: "lb")
                    case .oz: return #imageLiteral(resourceName: "oz")
                    }
                }()
                imageView.image = image

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
