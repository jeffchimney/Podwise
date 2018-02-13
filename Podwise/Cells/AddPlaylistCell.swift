//
//  AddPlaylistCell.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-29.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class AddPlaylistCell: UITableViewCell {
    
    @IBOutlet weak var playlistButton: UIButton!
    weak var editDelegate: editPlaylistDelegate!
    
    @IBAction func addPlaylistPressed(_ sender: Any) {
        editDelegate.edit()
    }
}
