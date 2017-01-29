//
//  DetailViewController.swift
//  MovieViewer
//
//  Created by Timothy Mak on 1/25/17.
//  Copyright © 2017 Timothy Mak. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    
    var movie: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)

        let title = movie["title"] as? String
        titleLabel.text = title
        
        let overview = movie["overview"]
        overviewLabel.text = overview as? String
        
        overviewLabel.sizeToFit()
        
        let baseUrl = "https://image.tmdb.org/t/p/w500"
        
        if let posterPath = movie["poster_path"] as? String{
            let posterUrl = NSURL(string: baseUrl + posterPath)
            posterImageView.setImageWith(posterUrl as! URL)
        }

        
        print(movie)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
