//
//  EmptyViewController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 28/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class EmptyViewController: UITableViewController {

    var labels: (label1: String, label2: String) = ("", "") {
        didSet {
            tableView.reloadData()
        }
    }
    
    fileprivate var pullToAddView: MyRefreshControl?

    weak var container: UIView?

    var onTapOrPull: (() -> Void)?
    
    var enabled: Bool = true {
        didSet {
            if enabled {
                container?.addSubview(view)
            } else {
                container?.removeSubviews()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enablePullToAdd()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func addTo(container: UIView) {
        container.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.fillSuperview()
        self.container = container
    }

    func enablePullToAdd() {
        let refreshControl = PullToAddHelper.createPullToAdd(self)
        refreshControl.addTarget(self, action: #selector(onPullRefresh(_:)), for: .valueChanged)
        self.refreshControl = refreshControl
        
        pullToAddView = refreshControl
    }
    
    func onPullRefresh(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        onTapOrPull?()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! EmptyViewCell
        cell.label1.text = labels.label1
        cell.label2.text = labels.label2
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.height
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pullToAddView?.updateForScrollOffset(offset: scrollView.contentOffset.y, startOffset: -40)
    }

    
    func onTap(_ sender: UITapGestureRecognizer) {
        onTapOrPull?()
    }
}
