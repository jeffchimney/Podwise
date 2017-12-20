//
//  HeaderView.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-12-13.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class HeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    var playlist: CDPlaylist!
    var headerTitle = ""
    weak var editDelegate: editPlaylistDelegate!
    
    @IBAction func editPlaylist(_ sender: UIButton) {
        editDelegate.edit(playlist: playlist)
    }
}
