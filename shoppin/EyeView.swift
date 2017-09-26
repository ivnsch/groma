//
//  EyeView.swift
//  shoppin
//
//  Created by ischuetz on 03/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit


protocol EyeViewDelegate: class {
    func onEyeChange(_ open: Bool)
}

class EyeView: UIView {

    fileprivate var openLabel: UILabel?

    fileprivate let dotDiameter: CGFloat = 10
    
    weak var delegate: EyeViewDelegate?

    fileprivate var open: Bool = true {
        didSet {
            openLabel?.isHidden = !open
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let x = (frame.width - dotDiameter) / 2
        let y = (frame.height - dotDiameter) / 2
        
        let path = UIBezierPath(ovalIn: CGRect(x: x, y: y, width: 10, height: 10))
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        let color = UIColor(hexString: "7F7F7F").cgColor
        shapeLayer.fillColor = color
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 1.0
        
        self.layer.addSublayer(shapeLayer)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor(hexString: "7F7F7F")
        label.text = "A"
        label.textAlignment = .center
        label.backgroundColor = UIColor.white
        addSubview(label)
        self.openLabel = label
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(EyeView.onTap(_:)))
        addGestureRecognizer(tapRecognizer)
    }
    
    func onTap(_ sender: UITapGestureRecognizer) {
        open = !open
        delegate?.onEyeChange(open)
    }
}
