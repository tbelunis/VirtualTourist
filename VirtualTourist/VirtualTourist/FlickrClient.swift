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
    
    func getPhotosForPin(pin: Pin, completionHandler: (result: [Photo?], error: NSError?) -> Void) -> Void {
        let methodArguments: [String : AnyObject] = [
            JSONBodyKeys.Method : Methods.FlickrSearchMethod,
            JSONBodyKeys.ApiKey : Constants.FlickrApiKey,
            JSONBodyKeys.SafeSearch : Constants.SafeSearch,
            JSONBodyKeys.BoundingBox : createBoundingBoxString(pin),
            JSONBodyKeys.Format : Constants.DataFormat,
            JSONBodyKeys.Extras : Constants.Extras,
            JSONBodyKeys.NoJSONCallback : Constants.NoJSONCallback,
            JSONBodyKeys.PerPage : Constants.PerPage
        ]
        
        let urlString = Constants.FlickrBaseUrl + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        let task = session.dataTaskWithRequest(request) { data, response, error in
            guard (error == nil) else {
                print("Could not complete the request \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            guard let data = data else {
                print("No data was returned")
                return
            }

            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            guard let photosDictionary = parsedResult.valueForKey("photos") as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }
            
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(parsedResult)")
                return
            }
            
            /* Flickr API - will only return up the 4000 images (21 per page * 21 page max) */
            let pageLimit = min(totalPages, 100)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
        }
        
        task.resume()
        
        //return self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)
       
    }
    
//    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: (result: [Photo?], error: NSError?) -> Void) -> NSURLSessionDataTask {
//        
//        var argumentsWithPage = methodArguments
//        argumentsWithPage["page"] = pageNumber
//        
//        let session = NSURLSession.sharedSession()
//        let urlString = FlickrClient.Constants.FlickrBaseUrl + escapedParameters(argumentsWithPage)
//        let url = NSURL(string: urlString)!
//        let request = NSURLRequest(URL: url)
//        
//        let task = session.dataTaskWithRequest(request) { (data, response, error) in
//            guard (error == nil) else {
//                print("Could not complete the request \(error)")
//            }
//            
//            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
//                if let response = response as? NSHTTPURLResponse {
//                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
//                } else if let response = response {
//                    print("Your request returned an invalid response! Response: \(response)!")
//                } else {
//                    print("Your request returned an invalid response!")
//                }
//                return
//            }
//            
//            guard let data = data else {
//                print("No data was returned")
//            }
//            
//            let parsedResult: AnyObject!
//            do {
//                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
//            } catch {
//                parsedResult = nil
//                print("Could not parse the data as JSON: '\(data)'")
//                return
//            }
//            
//            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
//                print("Flickr API returned an error. See error code and message in \(parsedResult)")
//                return
//            }
//            
//            guard let photosDictionary = parsedResult.valueForKey("photos") as? NSDictionary else {
//                print("Cannot find key 'photos' in \(parsedResult)")
//                return
//            }
//            
//            guard let totalPhotos = (photosDictionary["total"] as? NSString)?.integerValue else {
//                print("Cannot find key 'total' in \(parsedResult)")
//            }
//            
//           
//            
//    }
    
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
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}
