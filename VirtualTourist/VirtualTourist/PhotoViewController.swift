//
//  PhotoViewController.swift
//  VirtualTourist
//
//  Created by TOM BELUNIS on 9/17/15.
//  Copyright © 2015 TOM BELUNIS. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!

    @IBAction func newCollectionTouchUp(sender: AnyObject) {
    }


    var coordinates: CLLocationCoordinate2D!
    var photos: [Photo] = [Photo]()
    var photoUrls: [String] = []

    var pin: Pin!
    let reuseIdentifier = "PhotoCell"

    let fileManager = NSFileManager.defaultManager()

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    var fetchRequest = NSFetchRequest(entityName: "Photo")
    
    var fetchedResultsController: NSFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("pin = \(pin)")

        // Do any additional setup after loading the view.
        photoCollection.registerNib(UINib(nibName: "PhotoCellView", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
        photoCollection.delegate = self
        photoCollection.dataSource   = self
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "photo_pin == %@", self.pin)
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
            print("Fetched \(fetchedResultsController.fetchedObjects?.count) photos")
        } catch let error as NSError {
            print("Line 60 \(error)")
        }
        
        print("Line 62 \(fetchedResultsController.fetchedObjects?.count)")
        if fetchedResultsController.fetchedObjects?.count == 0 {
            FlickrClient.sharedInstance().getPhotosForPin(pin) { hasPhotos, error in
                guard (error == nil) else {
                    print("getPhotosForPin returned \(error)")
                    return
                }

                if hasPhotos {
                    do {
//                        self.fetchedResultsController.
                        try self.fetchedResultsController.performFetch()
                        print("Line 73 \(self.fetchedResultsController.fetchedObjects?.count)")
                        dispatch_async(dispatch_get_main_queue(), {
                            self.photoCollection.reloadData()
                        })

                    } catch let error as NSError {
                        print("Line 76 \(error)")
                    }
                } else {
                    print("No photos")
                }
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.photoCollection.reloadData()
            })
        }
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController.fetchedObjects?.count {
            return count
        } else {
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
//        dispatch_async(dispatch_get_main_queue(), {
            cell.image.image = UIImage(named: "placeholder")
            cell.activityIndicator.startAnimating()
//        })

        guard (fetchedResultsController.fetchedObjects?.count != 0) else {
            print("There are no images")
            return cell
        }
        
        let p = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

        var imageData: NSData?
        print("Photo path = \(p.path)")

        let photoPath = documentsDirectory.stringByAppendingPathComponent(p.path)
        if fileManager.fileExistsAtPath(photoPath) {
            imageData  = NSData(contentsOfFile: photoPath)!
            dispatch_async(dispatch_get_main_queue(), {
                cell.image.image = UIImage(data: imageData!)
                cell.activityIndicator.stopAnimating()
            })
        } else {
            FlickrClient.sharedInstance().getPhotoFromUrl(p.path) { data, error in
                if data != nil {
                    imageData = data
                    dispatch_async(dispatch_get_main_queue(), {
                        cell.image.image = UIImage(data: imageData!)
                        cell.activityIndicator.stopAnimating()
                    })
                } else {
                    print("no image available")
                    dispatch_async(dispatch_get_main_queue(), {
                    cell.activityIndicator.stopAnimating()})
                }
            }
        }

        return cell

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PhotoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let picDimension = self.view.frame.size.width / 4.0
        return CGSizeMake(picDimension, picDimension)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let leftRightInset = self.view.frame.size.width / 14.0
        return UIEdgeInsetsMake(0, leftRightInset, 0, leftRightInset)
    }
}

extension PhotoViewController: NSFetchedResultsControllerDelegate {

}
