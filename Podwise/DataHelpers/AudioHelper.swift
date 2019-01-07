//
//  AudioHelper.swift
//  Podwise
//
//  Created by Jeff Chimney on 2019-01-02.
//  Copyright © 2019 Jeff Chimney. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

// AVAudioPlayerDelegate Methods in BaseViewController
class AudioHelper {
    
    static func startAudioSession() {
        // set up background audio capabilities
        do {
            try audioSession.setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.default)))
            print("AVAudioSession Category Playback OK")
            do {
                try audioSession.setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    
    static func updateMediaPlayer(player: AVAudioPlayer) {
        let artworkImage = UIImage(data: nowPlayingEpisode.podcast!.image!)
        let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage!.size, requestHandler: { (size) -> UIImage in
            return artworkImage!
        })
        
        let mpic = MPNowPlayingInfoCenter.default()
        mpic.nowPlayingInfo = [MPMediaItemPropertyTitle:nowPlayingEpisode.title!,
                               MPMediaItemPropertyArtist:nowPlayingEpisode.podcast!.title!,
                               MPMediaItemPropertyArtwork: artwork,
                               MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
                               MPMediaItemPropertyPlaybackDuration: player.duration,
        ]
    }
    
    static func playDownload(for episode: CDEpisode) {
        startAudioSession()
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let componentToAppend = "\(episode.title ?? "")\(episode.audioURL!.lastPathComponent)"
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(componentToAppend)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: destinationUrl)
            guard let player = audioPlayer else { return }
            audioPlayer.delegate = baseViewController
            player.currentTime = TimeInterval(episode.progress)
            player.prepareToPlay()
            //startAudioSession()
            player.play()
            nowPlayingEpisode = episode
            
            let artworkImage = UIImage(data: episode.podcast!.image!)
            let artwork = MPMediaItemArtwork.init(boundsSize: artworkImage!.size, requestHandler: { (size) -> UIImage in
                return artworkImage!
            })
            
            let mpic = MPNowPlayingInfoCenter.default()
            mpic.nowPlayingInfo = [MPMediaItemPropertyTitle:episode.title!,
                                   MPMediaItemPropertyArtist:episode.podcast!.title!,
                                   MPMediaItemPropertyArtwork: artwork,
                                   MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
                                   MPMediaItemPropertyPlaybackDuration: player.duration
            ]
            
            baseViewController.miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-90"), for: .normal)
            baseViewController.showMiniPlayer(animated: true)
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionMode(_ input: AVAudioSession.Mode) -> String {
	return input.rawValue
}
