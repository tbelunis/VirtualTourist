
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
    @IBOutlet weak var newCollectionButton: UIButton!

    @IBOutlet var tapRecognizer: UITapGestureRecognizer?
    @IBAction func newCollectionTouchUp(sender: AnyObject) {
        fetchedResultsController = nil
        deletePhotosForPin(self.pin)
        loadPicturesFromFlickr(self.pin)
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

        setCenterOfMapToPin()
        newCollectionButton.enabled = false

        // Do any additional setup after loading the view.
        photoCollection.registerNib(UINib(nibName: "PhotoCollectionCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
        photoCollection.delegate = self
        photoCollection.dataSource   = self
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tappedCell:")
        self.photoCollection.addGestureRecognizer(tapRecognizer)
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "photo_pin == %@", self.pin)
        
        fetchedResultsController = getFetchedResultsController()
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            print("Fetched \(fetchedResultsController.fetchedObjects?.count) photos")
        } catch let error as NSError {
            print("Line 60 \(error)")
        }
        

        if fetchedResultsController.fetchedObjects?.count == 0 {
            loadPicturesFromFlickr(self.pin)
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.photoCollection.reloadData()
                self.newCollectionButton.enabled = true
            })
        }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        fetchedResultsController = nil
        super.viewDidDisappear(animated)
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
                    cell.activityIndicator.startAnimating()
            cell.image.image = UIImage(named: "placeholder")
//        cell.image.image.

//        })

        guard (fetchedResultsController.fetchedObjects?.count != 0) else {
            print("There are no images")
            return cell
        }
        
        let p = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

        var imageData: NSData?
//        print("Photo path = \(p.path)")

        let photoPath = documentsDirectory.stringByAppendingPathComponent(p.path)
        if fileManager.fileExistsAtPath(photoPath) {
            imageData  = NSData(contentsOfFile: photoPath)!
            dispatch_async(dispatch_get_main_queue(), {
                cell.image.image = UIImage(data: imageData!)
                cell.activityIndicator.stopAnimating()
            })
        } else {
            FlickrClient.sharedInstance().getPhotoFromUrl(p.url!) { data, error in
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
    
    func tappedCell(gestureRecognizer: UITapGestureRecognizer) {
        let tappedPoint: CGPoint = gestureRecognizer.locationInView(photoCollection)
        if let tappedCellPath: NSIndexPath = photoCollection.indexPathForItemAtPoint(tappedPoint) {
            let photo = fetchedResultsController.objectAtIndexPath(tappedCellPath) as! Photo
            sharedContext.deleteObject(photo)
            do {
                try sharedContext.save()
            } catch let error as NSError {
                print(error)
            }
        }
    }

    func getFetchedResultsController() -> NSFetchedResultsController {
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func deletePhotosForPin(aPin: Pin) {
        if aPin.pin_photo.count > 0 {
            for photo in aPin.pin_photo {
                sharedContext.deleteObject(photo as! Photo)
            }
            do {
                try sharedContext.save()
            } catch let error as NSError {
                print("Error clearing photos from Pin: \(error)")
            }
        }
    }
    
    func loadPicturesFromFlickr(aPin: Pin) {
        newCollectionButton.enabled = false
        fetchedResultsController = getFetchedResultsController()
        
        FlickrClient.sharedInstance().getPhotosForPin(aPin) { hasPhotos, error in
            guard (error == nil) else {
                print("getPhotosForPin returned \(error)")
                return
            }
            
            if hasPhotos {
                do {
                    try self.fetchedResultsController.performFetch()
                    dispatch_async(dispatch_get_main_queue(), {
                        self.photoCollection.reloadData()
                        self.newCollectionButton.enabled = true
                    })
                    
                } catch let error as NSError {
                    print("Line 76 \(error)")
                }
            } else {
                print("No photos")
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

    }

    
    func setCenterOfMapToPin() {
        let location = CLLocationCoordinate2DMake(pin.latitude as Double, pin.longitude as Double)
        let span = MKCoordinateSpanMake(FlickrClient.Constants.LatitudeDelta, FlickrClient.Constants.LongitudeDelta)
        let region = MKCoordinateRegionMake(location, span)
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView.addAnnotation(self.pin)
            self.mapView.setRegion(region, animated: true)
        })
    }

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
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        dispatch_async(dispatch_get_main_queue(), {
            self.photoCollection.reloadData()
        })
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            break
        case .Delete:
            photoCollection.deleteItemsAtIndexPaths([indexPath!])
            dispatch_async(dispatch_get_main_queue(), {
                self.photoCollection.reloadData()
            })
        case .Update:
            break
        case .Move:
            break
        }
    }
}
