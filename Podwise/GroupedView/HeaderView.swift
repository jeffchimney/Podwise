//
//  HeaderView.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-12-13.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class HeaderView: UIView {
    
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    var playlist: CDPlaylist!
    weak var editDelegate: editPlaylistDelegate!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)
        addSubview(headerView)
        headerView.frame = self.bounds
        headerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    @IBAction func editPlaylist(_ sender: Any) {
        editDelegate.edit(playlist: playlist)
    }
}
