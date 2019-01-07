//
//  SubCategoryViewController.swift
//  Podwise
//
//  Created by Jeff Chimney on 2018-01-03.
//  Copyright © 2018 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class SubCategoryViewController: UITableViewController {
    
    var category: String!
    var podcastResults: [[String: Any]] = []
    var subCategories: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if !hasSubcategories(category: category) {
            searchPodcastsIn(category: category)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasSubcategories(category: category) {
            return subCategories.count
        } else {
            return podcastResults.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if hasSubcategories(category: category) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "subCategoryCell")!
            cell.textLabel?.text = subCategories[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryResultCell", for: indexPath) as! PodcastCell
            let rowData: [String: Any] = self.podcastResults[indexPath.row]
            print(rowData)
            cell.titleLabel.text = rowData["trackName"] as? String
            cell.descriptionLabel.text = rowData["artistName"] as? String
            cell.collectionID = rowData["collectionId"] as? String
            let urlString: String = rowData["artworkUrl60"] as! String
            let url: URL = URL(string: urlString)!
            let request: URLRequest = URLRequest(url: url)
            let session: URLSession = URLSession.shared
            let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
                // Download representation of the image as NSData at the URL
                do {
                    let imageData: Data = try Data.init(contentsOf: url, options: .mappedIfSafe)
                    DispatchQueue.main.async {
                        cell.artImageView.image = UIImage(data: imageData)
                    }
                } catch {
                    print("Could not load art thumbnail")
                }
            })
            print("URL for searching iTunes API \(url)")
            task.resume()
            
            cell.artImageView.layer.cornerRadius = 3
            cell.artImageView.layer.masksToBounds = true
            
            return cell
        }
    }
    
    func searchPodcastsIn(category: String) {
        // replace spaces with + symbol.
        let iTunesTerm = category.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.caseInsensitive, range: nil)
        // anything that is URL friendly should be escaped
        let escapedTerm = iTunesTerm.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        //stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let path = "https://itunes.apple.com/search?term=podcast&genre=\(escapedTerm ?? "")&limit=50"
        let url: URL = URL(string: path)!
        let request: URLRequest = URLRequest(url: url)//NSURLRequest(URL: url as URL)
        let session: URLSession = URLSession.shared // NSURLConnection(request: rqst, delegate: self, startImmediately: false)!
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.ctnFinishedLoading(data: data!)
        })
        print("URL for searching iTunes API \(url)")
        task.resume()
    }
    
    func ctnFinishedLoading(data: Data) {
        // self.d should hold the resulting info, request is complete
        // received data is converted into an object through JSON deserialization
        do {
            let jResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! NSDictionary
            let results = jResult["results"] as! [[String: Any]]
            if jResult.count > 0 && results.count > 0 {
                print(results)
                self.podcastResults = results
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        } catch {
            
        }
    }
    
    func hasSubcategories(category: String) -> Bool {
        switch category {
        case "Arts":
            subCategories = ["Design",
                             "Fashion & Beauty",
                             "Food",
                             "Literature",
                             "Performing Arts",
                             "Visual Arts"]
            return true
        case "Business":
            subCategories = ["Business News",
                             "Careers",
                             "Investing",
                             "Management & Marketing",
                             "Shopping"]
            return true
        case "Comedy":
            return false
        case "Education":
            subCategories = ["Educational Technology",
                             "Higher Education",
                             "K-12",
                             "Language Courses",
                             "Training"]
            return true
        case "Games & Hobbies":
            subCategories = ["Automotive",
                             "Aviation",
                             "Hobbies",
                             "Other Games",
                             "Video Games"]
            return true
        case "Government & Organizations":
            subCategories = ["Local",
                             "National",
                             "Non-Profit",
                             "Regional"]
            return true
        case "Health":
            subCategories = ["Alternative Health",
                             "Fitness & Nutrition",
                             "Self-Help",
                             "Sexuality",
                             "Kids & Family"]
            return true
        case "Music":
            return false
        case "News & Politics":
            return false
        case "Religion & Spirituality":
            subCategories = ["Buddhism",
                             "Christianity",
                             "Hinduism",
                             "Islam",
                             "Judaism",
                             "Other",
                             "Spirituality"]
            return true
        case "Science & Medicine":
            subCategories = ["Medicine",
                             "Natural Sciences",
                             "Social Sciences"]
            return true
        case "Society & Culture":
            subCategories = ["History",
                             "Personal Journals",
                             "Philosophy",
                             "Places & Travel"]
            return true
        case "Sports & Recreation":
            subCategories = ["Amateur",
                             "College & High School",
                             "Outdoor",
                             "Professional",
                             "TV & Film"]
            return true
        case "Technology":
            subCategories = ["Gadgets",
                             "Podcasting",
                             "Software How-To",
                             "Tech News"]
            return true
        default:
            return false
        }
    }
}
