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

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity:entity, insertIntoManagedObjectContext: context)
    }
    
    init(path: String, pin: Pin, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.path = path
        self.photo_pin = pin
    }
}
