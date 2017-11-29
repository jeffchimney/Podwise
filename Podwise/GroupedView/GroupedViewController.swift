//
//  GroupedViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-28.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class GroupedViewController: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    var playlist: CDPlaylist?
    var misfitEpisodes: [CDEpisode] = []
    var episodesInPlaylist: [CDEpisode] = []
    var managedContext: NSManagedObjectContext!
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("GroupedView", owner: self, options: nil)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        self.register(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "PlaylistGroupCell")
        
        self.dataSource = self
        self.delegate = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodesInPlaylist.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return playlist?.name!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistGroupCell", for: indexPath as IndexPath) as! PlaylistCell
        let thisEpisode: CDEpisode = episodesInPlaylist[indexPath.row]
        print(thisEpisode.title!)
        cell.titleLabel.text = thisEpisode.title
        
        var hours = 0
        var minutes = 0
        if let optionalHours = Int(thisEpisode.duration!) {
            hours = (optionalHours/60)/60
        }
        if let optionalMinutes = Int(thisEpisode.duration!) {
            minutes = (optionalMinutes/60)%60
        }
        if hours == 0 && minutes == 0 {
            cell.durationLabel.text = ""
        } else if hours == 0 {
            cell.durationLabel.text = "\(minutes)m"
        } else {
            cell.durationLabel.text = "\(hours)h \(minutes)m"
        }
        
        if let imageData = thisEpisode.podcast?.image {
            cell.artImageView.image = UIImage(data: imageData)
        }
        
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true
        cell.activityIndicator.isHidden = true
        if downloads != nil {
            if downloads.contains(thisEpisode) {
                cell.activityIndicator.startAnimating()
                cell.activityIndicator.isHidden = false
                cell.isUserInteractionEnabled = false
            } else {
                cell.activityIndicator.isHidden = true
                cell.activityIndicator.stopAnimating()
                cell.isUserInteractionEnabled = true
            }
        }
        //cell.setNeedsDisplay()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playDownload(at: episodesInPlaylist[indexPath.row].localURL!)
    }
    
    func playDownload(at: URL) {
        startAudioSession()
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(at.lastPathComponent)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: destinationUrl)
            guard let player = audioPlayer else { return }
            
            player.prepareToPlay()
            player.play()
            baseViewController.miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            baseViewController.showMiniPlayer(animated: true)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func startAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .interruptSpokenAudioAndMixWithOthers)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
    
    func loadPlaylist() {
        DispatchQueue.main.async() {
            self.misfitEpisodes = []
            self.episodesInPlaylist = []
            let podcastsInPlaylist: [CDPodcast] = CoreDataHelper.fetchPodcastsFor(playlist: self.playlist!, in: self.managedContext!)
            for podcast in podcastsInPlaylist {
                let episodesForPodcastInPlaylist: [CDEpisode] = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: self.managedContext!)
                for episode in episodesForPodcastInPlaylist {
                    if episode.playlist != nil {
                        self.misfitEpisodes.append(episode)
                    }
                }
                self.episodesInPlaylist.append(contentsOf: episodesForPodcastInPlaylist)
            }
            // for episodes that have been assigned another playlist, remove them from this playlist
            for episode in self.misfitEpisodes {
                if self.episodesInPlaylist.contains(episode) {
                    let index = self.episodesInPlaylist.index(of: episode)
                    self.episodesInPlaylist.remove(at: index!)
                }
            }
            
            self.reloadData()
        }
    }
}


