//
//  SubscriptionsViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-12-14.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import MediaPlayer

class SubscriptionsViewController: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    var podcasts: [CDPodcast] = []
    var subscribed: Bool!
    var rowInTableView: Int!
    weak var relayoutSectionDelegate: relayoutSectionDelegate?
    var managedContext: NSManagedObjectContext!
    var previousViewController: PodcastsViewController!
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("SubscriptionsView", owner: self, options: nil)
        let headerViewNib = UINib(nibName: "HeaderView", bundle: nil)
        self.register(headerViewNib, forHeaderFooterViewReuseIdentifier: "SubscriptionSectionHeader")
        
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
        return podcasts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Dequeue with the reuse identifier
        let headerView = self.dequeueReusableHeaderFooterView(withIdentifier: "SubscriptionSectionHeader") as! HeaderView
        
        if subscribed != nil {
            if subscribed {
                headerView.label.text = "Subscribed"
                let subscribedColour = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
                headerView.contentView.backgroundColor = subscribedColour
            } else {
                headerView.label.text = "Not Subscribed"
                let unsubscribedColour = UIColor(displayP3Red: 255/255, green: 149/255, blue: 0, alpha: 1.0)
                headerView.contentView.backgroundColor = unsubscribedColour
            }
        }
    
        headerView.button.isHidden = true

        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistGroupCell", for: indexPath as IndexPath) as! PlaylistCell
        let thisPodcast: CDPodcast = podcasts[indexPath.row]
        
        let episodes = CoreDataHelper.fetchEpisodesFor(podcast: thisPodcast, in: managedContext!)
        
        if episodes.count == 0 {
            cell.episodeCounterLabel.isHidden = true
        } else {
            cell.episodeCounterLabel.text = String(episodes.count)
        }
        cell.titleLabel.text = thisPodcast.title
        cell.durationLabel.text = thisPodcast.author
        
        if let imageData = thisPodcast.image {
            cell.artImageView.image = UIImage(data: imageData)
        }
        
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true
        cell.activityIndicator.isHidden = true
        
        cell.episodeCounterLabel.backgroundColor = .black
        cell.episodeCounterLabel.textColor = .white
        
        cell.episodeCounterLabel.layer.cornerRadius = 9
        cell.episodeCounterLabel.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let podcast: CDPodcast = podcasts[indexPath.row]
        
        let resultViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "episodesViewController") as! EpisodesForPodcastViewController
        resultViewController.podcast = podcast
        previousViewController!.navigationController?.pushViewController(resultViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let addToPlaylistAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            let alert = UIAlertController(title: "Add To Playlist", message: "", preferredStyle: .actionSheet)
            
            let playlists = CoreDataHelper.fetchAllPlaylists(in: self.managedContext!)
            
            for eachPlaylist in playlists {
                alert.addAction(UIAlertAction(title: eachPlaylist.name, style: .default, handler: { (action) in
                    self.add(podcast: self.podcasts[indexPath.row], to: eachPlaylist)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.previousViewController!.present(alert, animated: true, completion: nil)
            success(true)
        })
        
        addToPlaylistAction.image = UIImage(named: "playlist")
        addToPlaylistAction.backgroundColor = UIColor(displayP3Red: 87/255.0, green: 112/255.0, blue: 170/255.0, alpha: 1.0)
        
        return UISwipeActionsConfiguration(actions: [addToPlaylistAction])
    }
    
    func add(podcast: CDPodcast, to playlist: CDPlaylist) {
        podcast.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
}



