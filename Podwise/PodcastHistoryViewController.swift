//
//  PodcastHistoryViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-17.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class PodcastHistoryViewController: UIViewController {
    
    var feedURL: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(feedURL)
        
        let urlString: String = feedURL
        let url: URL = URL(string: urlString)!
        let parser = RSSParser()
        
        parser.startParsingContentsOfURL(rssURL: url, with: { (complete) in
            print(complete)
            
        })
        print("Looking for: \(url)")
    }
}
