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
}
