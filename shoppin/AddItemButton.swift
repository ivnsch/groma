//
//  AddItemButton.swift
//  shoppin
//
//  Created by ischuetz on 20/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class AddItemButton: UIButton {
   
    var tapHandler: VoidFunction?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(hexString: "1FAC6A")
        setTitle(trans("add_button_title"), for: UIControlState())
        
        addTarget(self, action: #selector(AddItemButton.onTap(_:)), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func onTap(_ sender: AddItemButton) {
        tapHandler?()
    }
}
