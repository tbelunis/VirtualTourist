//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by TOM BELUNIS on 7/10/15.
//  Copyright (c) 2015 TOM BELUNIS. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    // Get the managed object context
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Prepare the map view
        mapView.mapType = .Standard
        mapView.delegate = self
        
        // Add the long press gesture recognizer to the map view
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addPinToMap:")
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        
        // Set the initial view of the map
        setInitialMapView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Set the pin for the PhotoViewController
        let photoController = segue.destinationViewController as! PhotoViewController
        let pin = sender as? Pin
        photoController.pin = pin
    }

    // Sets the initial view of the map and adds the pins to the map. The last view of the map is
    // stored in the user defaults, so the map will always appear as it did the last time the user 
    // used the app.
    func setInitialMapView() {
        let defaults = NSUserDefaults.standardUserDefaults()
        var mapDefaultsSet: Bool
        mapDefaultsSet = defaults.boolForKey(FlickrClient.NSUserDefaultKeys.StartMapPositionSaved)
       
        // There are stored values for the view of the map, so use them.
        if mapDefaultsSet {
            let startCenterLatitude = defaults.doubleForKey(FlickrClient.NSUserDefaultKeys.StartMapCenterLatitude)
            let startCenterLongitude = defaults.doubleForKey(FlickrClient.NSUserDefaultKeys.StartMapCenterLongitude)
            let startDeltaLatitude = defaults.doubleForKey(FlickrClient.NSUserDefaultKeys.StartMapDeltaLatitude)
            let startDeltaLongitude = defaults.doubleForKey(FlickrClient.NSUserDefaultKeys.StartMapDeltaLongitude)
            let centerCoordinate = CLLocationCoordinate2D(latitude: startCenterLatitude, longitude: startCenterLongitude)
            let centerSpan = MKCoordinateSpanMake(startDeltaLatitude, startDeltaLongitude)
            let region = MKCoordinateRegionMake(centerCoordinate, centerSpan)
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.setRegion(region, animated: true)
            })
        }
        
        // Now get all the pins that are stored in CoreData and add them to the map
        let pinFetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            let pins = try sharedContext.executeFetchRequest(pinFetchRequest) as! [Pin]
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotations(pins)
            })
            
        } catch let error as NSError {
            print("Error fetching pins from CoreData: \(error)")
        }
    }
    
    // Add a pin to the map when the user does a long press on the map.
    func addPinToMap(gestureRecogizer: UILongPressGestureRecognizer) {
        if gestureRecogizer.state == UIGestureRecognizerState.Ended {
            // Get the map coordinates from the point where the user pressed
            let coordinate = mapView.convertPoint(gestureRecogizer.locationInView(self.mapView), toCoordinateFromView: self.mapView)
            // Create a new pin
            let pin = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, photos: NSSet(), context: sharedContext)
            do {
            try
                self.sharedContext.save()
            } catch let error  as NSError {
                print("Error saving new pin: \(error)")
            }
            // Update the map view with the new pin
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotation(pin)
            })
        }
        
    }
    
    // Store the map settings in the user defaults when the map region changes so that the last view
    // of the map can be restored when the user starts the app the next time.
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let centerCoordinate = mapView.centerCoordinate
        let region = mapView.region
        let centerLatitude = centerCoordinate.latitude
        let centerLongitude = centerCoordinate.longitude
        let latitudeDelta = region.span.latitudeDelta
        let longitudeDelta = region.span.longitudeDelta
        let defaults = NSUserDefaults.standardUserDefaults()
        
        defaults.setDouble(centerLatitude, forKey: FlickrClient.NSUserDefaultKeys.StartMapCenterLatitude)
        defaults.setDouble(centerLongitude, forKey: FlickrClient.NSUserDefaultKeys.StartMapCenterLongitude)
        defaults.setDouble(latitudeDelta, forKey: FlickrClient.NSUserDefaultKeys.StartMapDeltaLatitude)
        defaults.setDouble(longitudeDelta, forKey: FlickrClient.NSUserDefaultKeys.StartMapDeltaLongitude)
        defaults.setBool(true, forKey: FlickrClient.NSUserDefaultKeys.StartMapPositionSaved)
    }
    
    // Get the view for the pin's annotation
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "pin"
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
        
        return view
    }
    
    // When the user taps the pin we will segue to the photo collection
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // Fetch the pin from CoreData based on the latitude and longitude of the annotation view.
        let fetchRequest = NSFetchRequest(entityName: "Pin")
    
        let latitudePredicate = NSPredicate(format: "latitude = %@", NSNumber(double: (view.annotation?.coordinate.latitude)!))
        let longitudePredicate = NSPredicate(format: "longitude = %@", NSNumber(double: (view.annotation?.coordinate.longitude)!))
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [latitudePredicate, longitudePredicate])
        var pin: Pin
        do {
            let result = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
            if result.count > 0 {
                pin = result.first! as Pin
                self.mapView.deselectAnnotation(view.annotation, animated: true)
                self.performSegueWithIdentifier("showPhotos", sender: pin)
            }
        } catch let error as NSError {
            print("Error fetching pin for the annotation view: \(error)")
        }
    }
}


