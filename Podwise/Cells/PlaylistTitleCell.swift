//
//  PlaylistTitleCell.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-27.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class PlaylistTitleCell: UITableViewCell {
    
    @IBOutlet weak var titleTextField: UILabel!
    @IBOutlet weak var editPlaylistButton: UIButton!
    
    var playlist: CDPlaylist!
    var headerTitle = ""
    weak var editDelegate: editPlaylistDelegate!
    
    @IBAction func editPlaylist(_ sender: UIButton) {
        editDelegate.edit(playlist: playlist)
    }
    
    override func layoutSubviews() {
        self.bounds = CGRect(x: self.bounds.origin.x,
                             y: self.bounds.origin.y,
                             width: self.bounds.size.width, // - 16
                             height: self.bounds.size.height)
        super.layoutSubviews()
        
        // round top left and right corners
        let cornerRadius: CGFloat = 15
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            ).cgPath
        
        self.layer.mask = maskLayer
    }
}
