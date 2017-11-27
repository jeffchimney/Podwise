//
//  FirstViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class PlaylistsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var podcasts: [CDPodcast] = []
    var episodes: [CDEpisode] = []
    var playlists: [CDPlaylist] = []
    var episodesForPlaylists: [[CDEpisode]] = [[CDEpisode]]()
    var managedContext: NSManagedObjectContext?
    var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        podcasts = CoreDataHelper.fetchAllPodcasts(in: managedContext!)
        episodes = []
        for podcast in podcasts {
            let episodesForPodcast = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
            for episode in episodesForPodcast {
                episodes.append(episode)
            }
        }
        
        episodesForPlaylists = []
        playlists = CoreDataHelper.fetchAllPlaylists(in: managedContext!)
        playlists.sort(by: { $0.name! < $1.name!})
        
        for playlist in playlists {
            let podcastsForPlaylist = CoreDataHelper.fetchPodcastsFor(playlist: playlist, in: managedContext!)
            var episodesForPlaylist:[CDEpisode] = []
            for podcast in podcastsForPlaylist {
                let episodesForPodcastInPlaylist = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
                episodesForPlaylist.append(contentsOf: episodesForPodcastInPlaylist)
            }
            episodesForPlaylists.append(episodesForPlaylist)
        }
        
        tableView.reloadData()
        
        if !isTimerRunning {
            runTimer()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return playlists.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return episodes.count
        }
        return episodesForPlaylists[section-1].count // section-1 to account for episodes with no playlist being put first
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return ""
        } else {
            return playlists[section-1].name!
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath as IndexPath) as! PlaylistCell
        
        let thisEpisode: CDEpisode!
        if indexPath.section == 0 {
            thisEpisode = episodes[indexPath.row]
        } else {
            thisEpisode = episodesForPlaylists[indexPath.section-1][indexPath.row]
        }
        
        
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
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        startAudioSession()
        nowPlayingArt = UIImage(data: (episodes[indexPath.row].podcast?.image)!)
        baseViewController.miniPlayerView.artImageView.image = nowPlayingArt
        baseViewController.setProgressBarColor(red: CGFloat(episodes[indexPath.row].podcast!.backgroundR), green: CGFloat(episodes[indexPath.row].podcast!.backgroundG), blue: CGFloat(episodes[indexPath.row].podcast!.backgroundB))
        playDownload(at: episodes[indexPath.row].localURL!)
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
            let cdEpisode = CoreDataHelper.getEpisodeWith(id: self.episodes[indexPath.row].id!, in: self.managedContext!)
            if cdEpisode.count > 0 {
                do {
                    let filemanager = FileManager.default
                    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0] as NSString
                    let destinationPath = documentsPath.appendingPathComponent(cdEpisode[0].localURL!.lastPathComponent)
                    if filemanager.fileExists(atPath: destinationPath) {
                        try! filemanager.removeItem(atPath: destinationPath)
                        tableView.beginUpdates()
                        CoreDataHelper.delete(episode: cdEpisode[0], in: self.managedContext!)
                        self.episodes.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                        tableView.endUpdates()
                    } else {
                        print("not deleted, couldnt find file.")
                    }
                }
            }
            success(true)
        })
        
        deleteEpisodeAction.image = UIImage(named: "trash")
        deleteEpisodeAction.backgroundColor = .red
        
        addToPlaylistAction.image = UIImage(named: "playlist")
        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
        
        return UISwipeActionsConfiguration(actions: [deleteEpisodeAction, addToPlaylistAction])
    }
    
    func playDownload(at: URL) {
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
    
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(checkDownloads)), userInfo: nil, repeats: true)
    }
    
    @objc func checkDownloads() {
        tableView.reloadData()
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
    
    @IBAction func addPlaylistButtonPressed(_ sender: Any) {
        
    }
    
}

