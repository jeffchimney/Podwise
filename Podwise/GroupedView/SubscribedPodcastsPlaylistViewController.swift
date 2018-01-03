//
//  SubscribedPodcastsPlaylistViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2017-12-18.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import MediaPlayer

public protocol savePlaylistDelegate: class {
    func saveButtonPressed(playlistName: String)
    func dismissPlaylist()
}

class SubscribedPodcastsPlaylistViewController: UITableView, UITableViewDataSource, UITableViewDelegate, savePlaylistDelegate {
    
    var podcasts: [CDPodcast] = []
    var playlist: CDPlaylist!
    var podcastsInPlaylist: [CDPodcast] = []
    var selectedPodcasts: [CDPodcast] = []
    var subscribed: Bool!
    var rowInTableView: Int!
    weak var relayoutSectionDelegate: relayoutSectionDelegate?
    var managedContext: NSManagedObjectContext!
    weak var previousViewController: PlaylistCreationTableViewController!
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("SubscribedPodcastsPlaylistView", owner: self, options: nil)
        let headerViewNib = UINib(nibName: "NewPlaylistHeaderView", bundle: nil)
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
        let headerView = self.dequeueReusableHeaderFooterView(withIdentifier: "SubscriptionSectionHeader") as! NewPlaylistHeaderView
        headerView.textField.delegate = headerView
        headerView.savePlaylistDelegate = self
        if playlist != nil {
            headerView.textField.text = playlist.name
            headerView.saveButton.setTitle("Save", for: .normal)
            
            let playlistColour = NSKeyedUnarchiver.unarchiveObject(with: playlist.colour!) as? UIColor
            headerView.contentView.backgroundColor = playlistColour
        } else {
            headerView.saveButton.setTitle("Create", for: .normal)
            headerView.contentView.backgroundColor = UIColor(displayP3Red: 0, green: 122/255, blue: 255/255, alpha: 1.0)
        }
        
        headerView.isUserInteractionEnabled = true
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistGroupCell", for: indexPath as IndexPath) as! PlaylistCell
        cell.episodeCounterLabel.isHidden = true
        let thisPodcast: CDPodcast = podcasts[indexPath.row]
        
        cell.titleLabel.text = thisPodcast.title
        cell.durationLabel.text = thisPodcast.author
        
        if podcastsInPlaylist.contains(podcasts[indexPath.row]) {
            cell.accessoryType = .checkmark
            selectedPodcasts.append(podcasts[indexPath.row])
        }

        cell.titleLabel.text = podcasts[indexPath.row].title
        cell.durationLabel.text = podcasts[indexPath.row].author

        if let imageData = podcasts[indexPath.row].image {
            cell.artImageView.image = UIImage(data: imageData)
        }
        
        cell.activityIndicator.isHidden = true
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let cell = tableView.cellForRow(at: indexPath) as! PlaylistCell
            if cell.accessoryType == .checkmark { // deselect row
                DispatchQueue.main.async {
                    cell.accessoryType = .none
                }
                if selectedPodcasts.contains(podcasts[indexPath.row]) {
                    let index = selectedPodcasts.index(of: podcasts[indexPath.row])
                    selectedPodcasts.remove(at: index!)
                    
                    removeFromPlaylist(podcast: podcasts[indexPath.row])
                }
            } else { // select row
                DispatchQueue.main.async {
                    cell.accessoryType = .checkmark
                }
                selectedPodcasts.append(podcasts[indexPath.row])
            }
        }
    }
    
    func add(podcast: CDPodcast, to playlist: CDPlaylist) {
        podcast.playlist = playlist
        CoreDataHelper.save(context: managedContext!)
    }
    
    func removeFromPlaylist(podcast: CDPodcast) {
        podcast.playlist = CoreDataHelper.fetchAllPlaylists(with: "Unsorted", in: managedContext!)[0]
        CoreDataHelper.save(context: managedContext!)
    }
    
    func saveButtonPressed(playlistName: String) {
        previousViewController.createPlaylist(playlistName: playlistName, selectedPodcasts: selectedPodcasts)
    }
    
    func dismissPlaylist() {
        previousViewController.dismiss(animated: true, completion: nil  )
    }
}




