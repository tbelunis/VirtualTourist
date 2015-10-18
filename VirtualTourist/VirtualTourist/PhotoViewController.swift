
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
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    @IBOutlet var tapRecognizer: UITapGestureRecognizer?
    
    // When the user taps the New Collection button, delete all the photos for the pin
    // and download new photos from Flickr.
    @IBAction func newCollectionTouchUp(sender: AnyObject) {
        fetchedResultsController = nil
        deletePhotosForPin()
        loadPicturesFromFlickr()
    }
    var pin: Pin!
    let reuseIdentifier = "PhotoCell"

    let fileManager = NSFileManager.defaultManager()

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    

    var fetchedResultsController: NSFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Display the pin on the small map above the photo collection
        setCenterOfMapToPin()
        
        // New Collection button is disabled until the photos have been loaded.
        newCollectionButton.enabled = false

        // Do any additional setup after loading the view.
        
        // Register the custom cell view and set the delegate and data source for 
        // the photo collection.
        photoCollection.registerNib(UINib(nibName: "PhotoCollectionCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
        photoCollection.delegate = self
        photoCollection.dataSource   = self
        
        // Add a tap gesture recognizer to the photoCollection
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tappedCell:")
        self.photoCollection.addGestureRecognizer(tapRecognizer)
        
        fetchedResultsController = getFetchedResultsController()
        
        do {
            try fetchedResultsController.performFetch()
            } catch let error as NSError {
            print("Error fetching photos for pin: \(error)")
        }
        
        // If the fetchedResultsController did not return any objects
        // then download the photos from Flickr. Otherwise, call reloadData 
        // to place the photos in the collection view.
        if fetchedResultsController.fetchedObjects?.count == 0 {
            loadPicturesFromFlickr()
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

    // The number of items for the section is the number of items returned 
    // from the fetchedResultsController.
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController.fetchedObjects?.count {
            return count
        } else {
            return 0
        }
    }

    // Return a cell with the photo image
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        cell.activityIndicator.hidden = false
        cell.activityIndicator.startAnimating()
        
        // Use a placeholder image until the actual image is loaded.
        cell.image.image = UIImage(named: "placeholder")


        // If there are no results returned from the fetch just return the cell
        guard (fetchedResultsController.fetchedObjects?.count != 0) else {
            return cell
        }
        
        // Get the photo from the fetchedResultsController for the indexPath
        let p = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

        var imageData: NSData?
        
        // Check and see if the photo image data has already been stored in the Documents
        // directory. If it has, then get the image data from the file and set the image 
        // property of the cell's image view.
        let photoPath = documentsDirectory.stringByAppendingPathComponent(p.path)
        if fileManager.fileExistsAtPath(photoPath) {
            imageData  = NSData(contentsOfFile: photoPath)!
            dispatch_async(dispatch_get_main_queue(), {
                cell.image.image = UIImage(data: imageData!)
                cell.activityIndicator.stopAnimating()
            })
        } else {
            // The image data is not in the Documents directory, so download it from Flickr.
            if let photoUrl = p.url {
                FlickrClient.sharedInstance().getPhotoFromUrl(photoUrl) { data, error in
                    // If we get data back set the cell's image with a UIImage from the data.
                    if data != nil {
                        imageData = data
                        dispatch_async(dispatch_get_main_queue(), {
                            cell.image.image = UIImage(data: imageData!)
                            cell.activityIndicator.stopAnimating()
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), {
                            cell.activityIndicator.stopAnimating()
                        })
                    }
                }
            }
        }

        return cell

    }
    
    // When a cell is tapped, delete the photo
    func tappedCell(gestureRecognizer: UITapGestureRecognizer) {
        // Map the point the user tapped to a cell in the photo collection view
        let tappedPoint: CGPoint = gestureRecognizer.locationInView(photoCollection)
        if let tappedCellPath: NSIndexPath = photoCollection.indexPathForItemAtPoint(tappedPoint) {
            let photo = fetchedResultsController.objectAtIndexPath(tappedCellPath) as! Photo
            sharedContext.deleteObject(photo)
            do {
                try sharedContext.save()
            } catch let error as NSError {
                print("Error deleting photo: \(error)")
            }
        }
    }

    // Returns a fetchedResultController for fetching photos associated with a pin
    func getFetchedResultsController() -> NSFetchedResultsController {
        // Fetch photo objects
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        // Sorted by id
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Where the photo is assocaited with the pin
        fetchRequest.predicate = NSPredicate(format: "photo_pin == %@", self.pin)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }
    
    // Delete all the photos associated with the pin
    func deletePhotosForPin() {
        if pin.pin_photo.count > 0 {
            for photo in pin.pin_photo {
                sharedContext.deleteObject(photo as! Photo)
            }
            do {
                try sharedContext.save()
            } catch let error as NSError {
                print("Error clearing photos from Pin: \(error)")
            }
        }
    }
    
    // Call the Flickr client to retrieve photos based on the location
    // of the pin.
    func loadPicturesFromFlickr() {
        newCollectionButton.enabled = false
        dispatch_async(dispatch_get_main_queue(), {
            self.noPhotosLabel.hidden = true
        })
        fetchedResultsController = getFetchedResultsController()
        
        FlickrClient.sharedInstance().getPhotosForPin(pin) { hasPhotos, error in
            guard (error == nil) else {
                print("getPhotosForPin returned an error: \(error)")
                return
            }
            
            if hasPhotos {
                do {
                    // Fetch the photos from CoreData and display them in the
                    // collection view.
                    try self.fetchedResultsController.performFetch()
                    dispatch_async(dispatch_get_main_queue(), {
                        self.photoCollection.reloadData()
                        self.newCollectionButton.enabled = true
                    })
                    
                } catch let error as NSError {
                    print("Error fetching photos for pin: \(error)")
                }
            } else {
                // No photos were found for the location specified by the
                // pin, so display the "No Photos" label
                dispatch_async(dispatch_get_main_queue(), {
                    self.noPhotosLabel.hidden = false
                })
                
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

    }
    */
    
    // Sets the view for the small map above the photos to center the pin in the map view.
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

// Methods to lay out the cells in the collection view.
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

    // When a photo is deleted, the fetchedResultsController has the photoCollection reload data
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
