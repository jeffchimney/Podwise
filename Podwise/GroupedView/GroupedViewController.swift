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
import MediaPlayer

//public protocol editPlaylistDelegate: class {
//    func edit(playlist: CDPlaylist)
//    func edit()
//}

class GroupedViewController: UITableView, UITableViewDataSource, UITableViewDelegate {//editPlaylistDelegate {
    
    var episodesInPlaylist: [CDEpisode] = []
    var rowInTableView: Int!
    weak var relayoutSectionDelegate: relayoutSectionDelegate?
    //weak var managedContext: NSManagedObjectContext!
    //weak var editPlaylistParentDelegate: editPlaylistParentDelegate!
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("GroupedView", owner: self, options: nil)
        let headerViewNib = UINib(nibName: "HeaderView", bundle: nil)
        self.register(headerViewNib, forHeaderFooterViewReuseIdentifier: "TableSectionHeader")
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        self.register(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "PlaylistGroupCell")
        
        self.dataSource = self
        self.delegate = self
        self.isScrollEnabled = false
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Dequeue with the reuse identifier
        let headerView = self.dequeueReusableHeaderFooterView(withIdentifier: "TableSectionHeader") as! HeaderView

        //headerView.editDelegate = self
        if episodesInPlaylist.count > 0 {
            if let podcastPlaylist = episodesInPlaylist[0].podcast?.playlist {
                headerView.playlist = podcastPlaylist
                
                let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: podcastPlaylist.colour!)
                
                headerView.contentView.backgroundColor = playlistColour as? UIColor
                
                headerView.label.text = podcastPlaylist.name!
                if podcastPlaylist.name! == "Unsorted" {
                    headerView.button.isHidden = true
                } else {
                    headerView.button.isHidden = false
                }
            }
        }
        
        headerView.isUserInteractionEnabled = true
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistGroupCell", for: indexPath as IndexPath) as! PlaylistCell
        cell.episodeCounterLabel.isHidden = true
        cell.percentDowloadedLabel.isHidden = true
        let thisEpisode: CDEpisode = episodesInPlaylist[indexPath.row]
        cell.titleLabel.text = thisEpisode.title

        var hours = 0
        var minutes = 0
        if let optionalHours = Int(thisEpisode.duration!) {
            hours = (optionalHours/60)/60
        }  else {
            print(thisEpisode.duration!)
            let durationArray = thisEpisode.duration?.split(separator: ":")
            if let optionalHours = Int(durationArray![0]) {
                hours = optionalHours
            }
        }
        if let optionalMinutes = Int(thisEpisode.duration!) {
            minutes = (optionalMinutes/60)%60
        }  else {
            let durationArray = thisEpisode.duration!.split(separator: ":")
            if let optionalMinutes = Int(durationArray[1]) {
                minutes = optionalMinutes
            }
        }
        
        cell.titleLabel.text = thisEpisode.title
        cell.durationLabel.text = thisEpisode.subTitle
        if hours == 0 && minutes == 0 {
            cell.durationLabel.text = ""
        } else if hours == 0 {
            cell.durationLabel.text = "\(minutes)m"
        } else {
            cell.durationLabel.text = "\(hours)h \(minutes)m"
        }
        
        DispatchQueue.main.async {
            if let imageData = thisEpisode.podcast?.image {
                cell.artImageView.image = UIImage(data: imageData)
            }
            
            cell.artImageView.layer.cornerRadius = 10
            cell.artImageView.layer.masksToBounds = true
        }
       
        if downloads != nil {
            for download in downloads {
                if download.episode == thisEpisode {
                    cell.isUserInteractionEnabled = false
                    break
                } else {
                    cell.isUserInteractionEnabled = true
                }
            }
        }
        //cell.setNeedsDisplay()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = episodesInPlaylist[indexPath.row]
        let podcast = episode.podcast!
        if nowPlayingEpisode != nil {
            nowPlayingEpisode.progress = Int64(audioPlayer.currentTime)
        }
        CoreDataHelper.save(context: managedContext)
        nowPlayingEpisode = episode
        let nowPlayingImage = UIImage(data: nowPlayingEpisode.podcast!.image!)
        baseViewController.miniPlayerView.artImageView.image = nowPlayingImage
        baseViewController.setProgressBarColor(red: CGFloat(podcast.backgroundR), green: CGFloat(podcast.backgroundG), blue: CGFloat(podcast.backgroundB))
        playDownload(for: episodesInPlaylist[indexPath.row])
        //baseViewController.setupNowPlaying(episode: episode)
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Update action ...")
            success(true)
        })

        let deleteEpisodeAction = UIContextualAction(style: .destructive, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            print("Delete action ...")
            let cdEpisode: CDEpisode = self.episodesInPlaylist[indexPath.row]
            let cdPlaylist: CDPlaylist = cdEpisode.playlist ?? (cdEpisode.podcast?.playlist)!
            let filemanager = FileManager.default
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
            let componentToAppend = "\(cdEpisode.title ?? "")\(cdEpisode.audioURL!.lastPathComponent)"
            let destinationPath = documentsPath.appendingPathComponent(componentToAppend)
            print("Deleting From: \(destinationPath)")
            if filemanager.fileExists(atPath: destinationPath) {
                try! filemanager.removeItem(atPath: destinationPath)
            } else {
                print("not deleted, couldnt find file.")
            }
            tableView.beginUpdates()
            CoreDataHelper.delete(episode: cdEpisode, in: managedContext!)
            self.episodesInPlaylist.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            self.relayoutSectionDelegate?.relayoutSection(section: self.rowInTableView, deleted: cdEpisode, playlist: cdPlaylist, episodesInPlaylist: self.episodesInPlaylist.count)
            success(true)
        })

        deleteEpisodeAction.image = UIImage(named: "trash")
        deleteEpisodeAction.backgroundColor = .red

        addToPlaylistAction.image = UIImage(named: "playlist")
        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)

        return UISwipeActionsConfiguration(actions: [deleteEpisodeAction, addToPlaylistAction])
    }
    
    func playDownload(for episode: CDEpisode) {
        //startAudioSession()
        // then lets create your document folder url
        let documentsDirectoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // lets create your destination file url
        let componentToAppend = "\(episode.title ?? "")\(episode.audioURL!.lastPathComponent)"
        let destinationUrl = documentsDirectoryURL.appendingPathComponent(componentToAppend)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: destinationUrl)
            guard let player = audioPlayer else { return }
            
            player.currentTime = TimeInterval(episode.progress)
            player.prepareToPlay()
            startAudioSession()
            player.play()
            
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
            
            baseViewController.miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            baseViewController.showMiniPlayer(animated: true)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func startAudioSession() {
        // set up background audio capabilities
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode(rawValue: convertFromAVAudioSessionMode(AVAudioSession.Mode.default)), options: .interruptSpokenAudioAndMixWithOthers)
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
    
    func reloadPlaylist() {
        self.reloadData()
    }
    
//    func edit(playlist: CDPlaylist) {
//        editPlaylistParentDelegate.edit(playlist: playlist)
//    }
//    
//    func edit() {
//        editPlaylistParentDelegate.edit()
//    }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionMode(_ input: AVAudioSession.Mode) -> String {
	return input.rawValue
}
