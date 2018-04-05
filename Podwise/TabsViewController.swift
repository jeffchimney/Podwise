//
//  TabsViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-04-05.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation

class TabsViewController: UITabBarController {
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self,selector: #selector(episodeReceived(notification:)),
                                               name: NSNotification.Name(rawValue: "EpisodeReceived"),
                                               object: nil)
    }
    
    
    @objc func episodeReceived(notification: NSNotification){
        print(self.selectedIndex)
        print(self.selectedViewController)
        
        DispatchQueue.main.async {
            self.selectedIndex = 0
            if let playlistViewController = self.viewControllers![0] as? PlaylistsViewController {
                playlistViewController.viewWillAppear(true)
            }
        }
    }
}
