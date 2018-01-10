//
//  PlaylistHeaderView.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-01-09.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class PlaylistHeaderView: UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    var playlist: CDPlaylist!
    var headerTitle = ""
    weak var editDelegate: editPlaylistDelegate!
    @IBOutlet weak var cellBackgroundView: UIView!
    
    @IBAction func editPlaylist(_ sender: UIButton) {
        editDelegate.edit(playlist: playlist)
    }
}
