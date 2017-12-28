//
//  Download.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-12-27.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation

class Download {
    var url: URL!
    var audioUrl: URL!
    var episode: CDEpisode!
    var parsedEpisode: Episode!
    var percentDown: Float = 0
    var playNow = false
    var indexPath: IndexPath?
    var addTo: CDPlaylist?
    
    init(url: URL, audioUrl: URL, episode: CDEpisode, parsedEpisode: Episode, playNow: Bool, indexPath: IndexPath, addTo: CDPlaylist) {
        self.url = url
        self.audioUrl = audioUrl
        self.episode = episode
        self.parsedEpisode = parsedEpisode
        self.playNow = playNow
        self.indexPath = indexPath
        self.addTo = addTo
    }
    
    func setPercentDown(to: Float) {
        percentDown = to
    }
    
}

