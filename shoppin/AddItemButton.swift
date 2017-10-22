//
//  AddItemButton.swift
//  shoppin
//
//  Created by ischuetz on 20/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class AddItemViewNew: UIView {
    
    init(frame: CGRect, tapHandler: VoidFunction?) {
        super.init(frame: frame)
        
        backgroundColor = Theme.lightGreyBackground

        let leftRight: CGFloat = 25
        let topBottom: CGFloat = 10
        
        let button = AddItemButton(frame: CGRect(x: leftRight, y: topBottom, width: frame.width - leftRight * 2, height: frame.height - topBottom * 2))
        button.tapHandler = tapHandler
        addSubview(button)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

class AddItemButton: UIButton {
   
    var tapHandler: VoidFunction?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = Theme.lighterGreen
        setTitleColor(UIColor.white, for: .normal)
        
        setTitle(trans("add_button_title"), for: UIControlState())
        
        layer.cornerRadius = 18
        
        addTarget(self, action: #selector(AddItemButton.onTap(_:)), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    @objc func onTap(_ sender: AddItemButton) {
        tapHandler?()
    }
}
