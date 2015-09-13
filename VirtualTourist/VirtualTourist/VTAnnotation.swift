//
//  VTAnnotation.swift
//  VirtualTourist
//
//  Created by TOM BELUNIS on 9/13/15.
//  Copyright (c) 2015 TOM BELUNIS. All rights reserved.
//

import Foundation
import MapKit

class VTAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0,0)
    var title: String!
    var subtitle: String!
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}