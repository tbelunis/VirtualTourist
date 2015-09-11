//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by TOM BELUNIS on 7/21/15.
//  Copyright (c) 2015 TOM BELUNIS. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient: NSObject {
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func getPhotosForPin(pin: Pin, completionHandler: (result: [Photo?], error: NSError) -> Void) -> NSURLSessionDataTask {
        let methodArguments = [
            JSONBodyKeys.Method : Methods.FlickrSearchMethod,
            JSONBodyKeys.ApiKey : Constants.FlickrApiKey,
            JSONBodyKeys.SafeSearch : Constants.SafeSearch,
            JSONBodyKeys.BoundingBox : createBoundingBoxString(pin),
            JSONBodyKeys.Format : Constants.DataFormat,
            JSONBodyKeys.Extras : Constants.Extras,
            JSONBodyKeys.NoJSONCallback : Constants.NoJSONCallback,
            JSONBodyKeys.PerPage : Constants.PerPage
        ]
        
        let urlString = Constants.FlickrBaseUrl + escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                println("Could not complete the request \(error)")
            } else {
                
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                        let pageLimit = min(totalPages, 40)
//                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
//                        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)
                        
                    } else {
                        println("Cant find key 'pages' in \(photosDictionary)")
                    }
                } else {
                    println("Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
        
        return task
        
    }
    
    func createBoundingBoxString(pin: Pin) -> String {
        
        let latitude = pin.latitude as Double
        let longitude = pin.longitude as Double
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - Constants.BoundingBoxHeight, Constants.MinimumLongitude)
        let bottom_left_lat = max(latitude - Constants.BoundingBoxHeight, Constants.MinimumLatitude)
        let top_right_lon = min(longitude + Constants.BoundingBoxHeight, Constants.MaximumLongitude)
        let top_right_lat = min(latitude + Constants.BoundingBoxHeight, Constants.MaximumLatitude)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}
