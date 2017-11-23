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

var audioPlayer:AVAudioPlayer!
var downloads: [CDEpisode]!
var nowPlayingArt: UIImage!

class PlaylistsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var podcasts: [CDPodcast] = []
    var episodes: [CDEpisode] = []
    var managedContext: NSManagedObjectContext?
    var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var miniPlayerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var miniPlayerView: MiniPlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        miniPlayerView.artImageView.layer.cornerRadius = 10
        miniPlayerView.artImageView.layer.masksToBounds = true
        
        if audioPlayer != nil {
            showMiniPlayer(animated: false)
        } else {
            hideMiniPlayer(animated: false)
        }
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
            let episodesForPodcase = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
            for episode in episodesForPodcase {
                episodes.append(episode)
            }
        }
        
        tableView.reloadData()
        
        if !isTimerRunning {
            runTimer()
        }
        
        if audioPlayer != nil {
            showMiniPlayer(animated: false)
        } else {
            hideMiniPlayer(animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath as IndexPath) as! PlaylistCell
        
        cell.titleLabel.text = episodes[indexPath.row].title
        
        var hours = 0
        var minutes = 0
        if let optionalHours = Int(episodes[indexPath.row].duration!) {
            hours = (optionalHours/60)/60
        }
        if let optionalMinutes = Int(episodes[indexPath.row].duration!) {
            minutes = (optionalMinutes/60)%60
        }
        if hours == 0 && minutes == 0 {
            cell.durationLabel.text = ""
        } else if hours == 0 {
            cell.durationLabel.text = "\(minutes)m"
        } else {
            cell.durationLabel.text = "\(hours)h \(minutes)m"
        }
        
        if let imageData = episodes[indexPath.row].podcast?.image {
            cell.artImageView.image = UIImage(data: imageData)
        }
        
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true
        cell.activityIndicator.isHidden = true
        if downloads != nil {
            if downloads.contains(episodes[indexPath.row]) {
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
        playDownload(at: episodes[indexPath.row].localURL!)
        nowPlayingArt = UIImage(data: (episodes[indexPath.row].podcast?.image)!)
        miniPlayerView.artImageView.image = nowPlayingArt
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
            miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            showMiniPlayer(animated: true)
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
    
    func hideMiniPlayer(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 1, animations: {
                self.miniPlayerHeightConstraint.constant = 0
                self.miniPlayerView.alpha = 0
            })
        } else {
            self.miniPlayerHeightConstraint.constant = 0
            self.miniPlayerView.alpha = 0
        }
    }
    
    func showMiniPlayer(animated: Bool) {
        if audioPlayer != nil {
            miniPlayerView.artImageView.image = nowPlayingArt
            if audioPlayer.isPlaying {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "pause-50"), for: .normal)
            } else {
                miniPlayerView.playPauseButton.setImage(UIImage(named: "play-50"), for: .normal)
            }
        }
        if animated {
            UIView.animate(withDuration: 1, animations: {
                self.miniPlayerHeightConstraint.constant = 70
                self.miniPlayerView.alpha = 1
            })
        } else {
            self.miniPlayerHeightConstraint.constant = 70
            self.miniPlayerView.alpha = 1
        }
    }
}

