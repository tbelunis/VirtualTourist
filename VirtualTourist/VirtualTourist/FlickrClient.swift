//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by TOM BELUNIS on 7/21/15.
//  Copyright (c) 2015 TOM BELUNIS. All rights reserved.
//

import Foundation
import UIKit
import CoreData

typealias PhotoCompletionHandler = (result: Bool, error: NSError?) -> Void
typealias PhotoDataCompletionHandler = (data: NSData?, error: NSError?) -> Void


let documentsDirectory: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]

// This class borrows heavily from the Swift 2.0 code from the iOS Networking class FlickrFinder project
class FlickrClient: NSObject {
    var session: NSURLSession
    
    // Static var to keep track of the next page of data to ask Flickr for.
    static var page = 0
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    // Run a task to get the photos associated with the location of a pin.
    func getPhotosForPin(pin: Pin, completionHandler: PhotoCompletionHandler) -> Void {
        
        let methodArguments: [String : AnyObject] = [
            JSONBodyKeys.Method : Methods.FlickrSearchMethod,
            JSONBodyKeys.ApiKey : Constants.FlickrApiKey,
            JSONBodyKeys.SafeSearch : Constants.SafeSearch,
            JSONBodyKeys.BoundingBox : createBoundingBoxString(pin),
            JSONBodyKeys.Format : Constants.DataFormat,
            JSONBodyKeys.NoJSONCallback : Constants.NoJSONCallback,
            JSONBodyKeys.PerPage : Constants.PerPage
        ]
        
        let urlString = Constants.FlickrBaseUrl + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        var totalPages = 0
        
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
            
            if let pages = photosDictionary["pages"] as? Int {
                totalPages = pages
            }
            
            // If totalPages == 0, then there are no photos, so call the completion handler
            // with a result of false
            if totalPages == 0 {
                completionHandler(result: false, error: nil)
                return
            }
            
            // Increase the page by one so that getting a new collection will retrieve new photos.
            // If we've gone past the number of available pages, then reset the page to 1.
            if ++FlickrClient.page > totalPages {
                FlickrClient.page = 1
            }
        }
        
        task.resume()
        
        // Call the method to get photos from a specific page
        return self.getImageFromFlickrBySearchWithPage(pin, methodArguments: methodArguments, pageNumber: FlickrClient.page, completionHandler: completionHandler)
       
    }
    
    // Retrieve photos from Flickr for a given page number
    func getImageFromFlickrBySearchWithPage(pin: Pin, methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: PhotoCompletionHandler) -> Void {
        
        var argumentsWithPage = methodArguments
        argumentsWithPage["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = FlickrClient.Constants.FlickrBaseUrl + escapedParameters(argumentsWithPage)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
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
            
            guard let totalPhotos = (photosDictionary["total"] as? NSString)?.integerValue else {
                print("Cannot find key 'total' in \(parsedResult)")
                return
            }
            
            if totalPhotos > 0 {
                guard let photosArray = photosDictionary["photo"] as? [[String : AnyObject]] else {
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                let photoSet: NSMutableSet = NSMutableSet()
                
                // For each result returned from Flickr, create a photo object and add it to 
                // the set of photos
                for photo in photosArray {
                    
                    // Create a new Photo object
                    let newPhoto = Photo(url: self.getFlickrUrlForPhoto(photo), pin: pin, context: self.sharedContext)
                    
                    // Get the image data from the photo's URL and store it in the Documents directory
                    self.getPhotoFromUrl(newPhoto.url!) { data, error in
                        guard (error == nil) else {
                            return
                        }
                    }
                    photoSet.addObject(newPhoto)
                }
                
                // If we've added photos to the set, set the pin's photos to the photo set and save
                // the context.
                if photoSet.count > 0 {
                    pin.pin_photo = photoSet
                    do {
                        try self.sharedContext.save()
                    } catch let error2 as NSError {
                        print("Error saving context for pin photos \(error2)")
                    }
                    
                }
                completionHandler(result: true, error: nil)
            }
        }
        task.resume()
        
    }
    
    // Retrieve the photo image data from Flickr using the URL of the photo.
    // This will run in the background.
    func getPhotoFromUrl(url: NSURL, completionHandler: PhotoDataCompletionHandler) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            // If Flickr returned data, then write it to the Documents directory
            if let imageData = NSData(contentsOfURL:url) {
                let photoPath = documentsDirectory.stringByAppendingPathComponent(url.lastPathComponent!)
                imageData.writeToFile(photoPath, atomically: true)
                completionHandler(data: imageData, error: nil)
            } else {
                completionHandler(data: nil, error: NSError(domain: "getPhotoFromUrl", code: -1, userInfo: [NSLocalizedDescriptionKey : "Could not retrieve image fron url"]))
            }
        }
    }
    
    
    // Create the latitude and longitude values for the bbox parameter in the Flickr search request.
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
    
    // Check the HTTP response, return a success flag and the status code
    func checkHttpResponse(response: NSURLResponse) -> (success: Bool, statusCode: Int) {
        // Cast response to NSHTTPURLResponse to get access to the status code
        let httpResponse: NSHTTPURLResponse = response as! NSHTTPURLResponse
        let statusCode = httpResponse.statusCode
        
        // Any status code within the range of 200 - 299 will be considered success
        let success = statusCode >= Constants.HttpSuccessRange.startIndex && statusCode <= Constants.HttpSuccessRange.endIndex
        return (success, statusCode)
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
    
    // Returns the URL for a Flickr photo from the photo data Flickr sent back in the response.
    func getFlickrUrlForPhoto(photoData : [String : AnyObject]) -> NSURL {
        // The URL has the form: https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
        var farm = photoData[JSONResponseKeys.Farm] as? String
        if farm == nil {
            farm = "1"
        }
        let server = photoData[JSONResponseKeys.Server] as? String
        let id = photoData[JSONResponseKeys.Id] as? String
        let secret = photoData[JSONResponseKeys.Secret] as? String
        
        return NSURL(string: "https://farm\(farm!).staticflickr.com/\(server!)/\(id!)_\(secret!)_m.jpg")!
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}
