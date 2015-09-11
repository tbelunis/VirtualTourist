//
//  Constants.swift
//  VirtualTourist
//
//  Created by TOM BELUNIS on 7/21/15.
//  Copyright (c) 2015 TOM BELUNIS. All rights reserved.
//

import Foundation

extension FlickrClient {
    struct Constants {
        static let FlickrApiKey = "d9a1e2ba78c6cdc8b7f4ee9d404fa597"
        static let FlickrBaseUrl = "https://api.flickr.com/services/rest/"
        static let BoundingBoxHeight = 1.0
        static let BoundingBoxWidth = 1.0
        static let Extras = "m_url"
        static let DataFormat = "json"
        static let SafeSearch = "1"
        static let NoJSONCallback = "1"
        static let MinimumLatitude = -90.0
        static let MaximumLatitude = 90.0
        static let MinimumLongitude = -180.0
        static let MaximumLongitude = 180.0
        static let PerPage = 21
    }
    
    struct Methods {
        static let FlickrSearchMethod = "flickr.photos.search"
    }
    
    struct JSONBodyKeys {
        static let Method = "method"
        static let ApiKey = "api_key";
        static let BoundingBox = "bbox"
        static let MinTakenDate = "min_taken_date"
        static let SafeSearch = "safe_search"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let PerPage = "perpage"
    }

    struct JSONResponseKeys {
        static let Page = "page"
        static let Pages = "pages"
        static let PerPage = "perpage"
        static let Total = "total"
        static let Id = "id"
        static let Secret = "secret"
        static let Server = "server"
        static let Title = "title"
        static let IsPublic = "ispublic"
    }
}