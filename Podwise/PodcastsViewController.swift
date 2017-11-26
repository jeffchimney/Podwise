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
    
    var subscribedPodcasts: [CDPodcast] = []
    var unSubscribedPodcasts: [CDPodcast] = []
    var managedContext: NSManagedObjectContext?

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        subscribedPodcasts = CoreDataHelper.getPodcastsWhere(subscribed: true, in: managedContext!)
        subscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        let unSubscribedPodcastsUnfiltered = CoreDataHelper.getPodcastsWhere(subscribed: false, in: managedContext!)
        unSubscribedPodcasts = []
        for podcast in unSubscribedPodcastsUnfiltered {
            let episodesForPodcast = CoreDataHelper.fetchEpisodesFor(podcast: podcast, in: managedContext!)
            if episodesForPodcast.count > 0 {
                unSubscribedPodcasts.append(podcast)
            }
        }
        unSubscribedPodcasts.sort(by: { $0.title! < $1.title!})
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return subscribedPodcasts.count
        } else {
            return unSubscribedPodcasts.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var podcastListForSection: [CDPodcast] = []
        if indexPath.section == 0 {
            podcastListForSection = subscribedPodcasts
        } else {
            podcastListForSection = unSubscribedPodcasts
        }
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "PodcastCell", for: indexPath as IndexPath) as! PodcastListCell
        
        cell.titleLabel.text = podcastListForSection[indexPath.row].title
        cell.authorLabel.text = podcastListForSection[indexPath.row].author
        if let imageData = podcastListForSection[indexPath.row].image {
            cell.artImageView.image = UIImage(data: imageData)
        }
        
        cell.artImageView.layer.cornerRadius = 10
        cell.artImageView.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var podcastListForSection: [CDPodcast] = []
        if indexPath.section == 0 {
            podcastListForSection = subscribedPodcasts
        } else {
            podcastListForSection = unSubscribedPodcasts
        }
        
        let podcast: CDPodcast = podcastListForSection[indexPath.row]
        
        let resultViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "episodesViewController") as! EpisodesForPodcastViewController
        resultViewController.podcast = podcast
        self.navigationController?.pushViewController(resultViewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return  "Subscribed"
        } else {
            return  "Not Subscribed"
        }
    }
}

