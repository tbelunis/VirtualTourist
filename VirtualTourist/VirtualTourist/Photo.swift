//
//  Photo.swift
//  VirtualTourist
//
//  Created by TOM BELUNIS on 7/21/15.
//  Copyright (c) 2015 TOM BELUNIS. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {

    @NSManaged var path: String
    @NSManaged var id: NSNumber
    @NSManaged var photo_pin: Pin

}
