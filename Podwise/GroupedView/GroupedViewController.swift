//
//  GroupedViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-28.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit

class GroupedViewController: UITableViewController {
    
    @IBOutlet var groupedView: UITableView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("MiniPlayer", owner: self, options: nil)
        addSubview(groupedView)
        groupedView.frame = self.bounds
        groupedView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}


