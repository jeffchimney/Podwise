//
//  ShowNotesViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-05-02.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class ShowNotesViewController: UIViewController {
    
    var episode: CDEpisode!
    
    @IBOutlet var podcastLabel: UILabel!
    @IBOutlet var episodeLabel: UILabel!
    @IBOutlet var showNotesView: UITextView!
    
    override func viewDidLoad() {
        podcastLabel.text = episode.podcast!.title!
        episodeLabel.text = episode.title!
        showNotesView.attributedText = episode.showNotes!.htmlToAttributedString
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let cancel = UIPreviewAction(title: "Cancel", style: .destructive) { (action, controller) in
            print("Cancel Action Selected")
        }
        
        return [cancel]
    }
}
