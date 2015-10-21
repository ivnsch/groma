//
//  AddElementViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

private enum Content {
    case Product, Group
}

private typealias Segment = (content: Content, segmentText: String)

class AddElementViewController: UIViewController {

    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private var segments: [Segment] = [
        Segment(content: .Product, segmentText: "Product"),
        Segment(content: .Group, segmentText: "Group"),
    ]
    
    var productDelegate: AddEditListItemControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        initSegments()
        selectContent(.Product)
    }
    
    func initSegments() {
        for (index, segment) in segments.enumerate() {
            segmentedControl.setTitle(segment.segmentText, forSegmentAtIndex: index)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onSegmentChanged(sender: UISegmentedControl) {
        selectContent(segments[sender.selectedSegmentIndex].content)
    }
    
    private func selectContent(content: Content) {
    
        let controller: UIViewController = {
            switch content {
            case .Product:
                let c = UIStoryboard.addEditListItemViewController()
                c.delegate = productDelegate
                return c
            case .Group:
                // TODO
                let c = UIStoryboard.addEditListItemViewController()
                c.delegate = productDelegate
                return c
            }
        }()

        removeChildViewControllers()
        contentContainer.removeSubviews()
        
        addChildViewControllerAndMove(controller)
        contentContainer.addSubview(controller.view)
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.fill(contentContainer)
    }
}