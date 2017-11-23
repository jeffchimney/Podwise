//
//  SecondViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-11-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

class PodcastsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var podcasts: [CDPodcast] = []
    var managedContext: NSManagedObjectContext?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var miniPlayerView: MiniPlayerView!
    @IBOutlet weak var miniPlayerHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.dataSource = self
        tableView.delegate = self
        
        miniPlayerView.artImageView.layer.cornerRadius = 10
        miniPlayerView.artImageView.layer.masksToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        podcasts = CoreDataHelper.fetchAllPodcasts(in: managedContext!)
//        episodes = []
//        for podcast in podcasts {
//            let episodesForPodcase = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
//            for episode in episodesForPodcase {
//                episodes.append(episode)
//            }
//        }
        
        if audioPlayer != nil {
            showMiniPlayer(animated: false)
        } else {
            hideMiniPlayer(animated: false)
        }
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return podcasts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PodcastCell", for: indexPath as IndexPath) as! PodcastListCell
        
        cell.titleLabel.text = podcasts[indexPath.row].title
        cell.authorLabel.text = podcasts[indexPath.row].author
        if let imageData = podcasts[indexPath.row].image {
            cell.artImageView.image = UIImage(data: imageData)
        }
        
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast: CDPodcast = self.podcasts[indexPath.row]
        
        let resultViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "episodesViewController") as! EpisodesForPodcastViewController
        resultViewController.podcast = podcast
        self.navigationController?.pushViewController(resultViewController, animated: true)
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

