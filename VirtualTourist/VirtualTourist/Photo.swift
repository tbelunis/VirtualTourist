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
    var url: NSURL?

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity:entity, insertIntoManagedObjectContext: context)
    }
    
    init(url: NSURL, pin: Pin, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.url = url
        self.path = (url.lastPathComponent)!
        self.photo_pin = pin

    }
    
    override func prepareForDeletion() {
        let photoPath = documentsDirectory.stringByAppendingPathComponent(path)
        do {
            if NSFileManager.defaultManager().fileExistsAtPath(photoPath) {
                try NSFileManager.defaultManager().removeItemAtPath(photoPath)
            }
        } catch let error as NSError {
            print(error)
        }
    }

    
}




