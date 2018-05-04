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
        
        let newAttributedString = NSMutableAttributedString(attributedString: episode.showNotes!.htmlToAttributedString!)
        
        // Enumerate through all the font ranges
        newAttributedString.enumerateAttribute(NSAttributedStringKey.font, in: NSMakeRange(0, newAttributedString.length), options: [])
        {
            value, range, stop in
            guard let currentFont = value as? UIFont else {
                return
            }
            
            // An NSFontDescriptor describes the attributes of a font: family name, face name, point size, etc.
            // Here we describe the replacement font as coming from the "Hoefler Text" family
            let fontDescriptor = currentFont.fontDescriptor//.addingAttributes([UIFontDescriptor.AttributeName.family: "Hoefler Text"])
            
            // Ask the OS for an actual font that most closely matches the description above
            if let newFontDescriptor = fontDescriptor.matchingFontDescriptors(withMandatoryKeys: [UIFontDescriptor.AttributeName.family]).first {
                let newFont = UIFont(descriptor: newFontDescriptor, size: 15.0)
                newAttributedString.addAttributes([NSAttributedStringKey.font: newFont], range: range)
            }
        }
        
        showNotesView.attributedText = newAttributedString
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let cancel = UIPreviewAction(title: "Cancel", style: .destructive) { (action, controller) in
            print("Cancel Action Selected")
        }
        
        return [cancel]
    }
}
