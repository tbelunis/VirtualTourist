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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mapView.mapType = .Standard
        mapView.delegate = self
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addPinToMap:")
        
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        activityIndicator.hidden = true
        setInitialMapView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let photoController = segue.destinationViewController as! PhotoViewController
        let pin = sender as? Pin
        photoController.pin = pin
    }


    func setInitialMapView() {
        let defaults = NSUserDefaults.standardUserDefaults()
        var mapDefaultsSet: Bool
        mapDefaultsSet = defaults.boolForKey(FlickrClient.NSUserDefaultKeys.StartMapPositionSaved)
       
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
        
        let pinFetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            let pins = try sharedContext.executeFetchRequest(pinFetchRequest) as! [Pin]
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotations(pins)
            })
            
        } catch let error1 as NSError {
            print(error1)
        }
    }
    
    func addPinToMap(gestureRecogizer: UILongPressGestureRecognizer) {
        if gestureRecogizer.state == UIGestureRecognizerState.Ended {
            print("Detected long press")
            let coordinate = mapView.convertPoint(gestureRecogizer.locationInView(self.mapView), toCoordinateFromView: self.mapView)
            let pin = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, photos: NSSet(), context: sharedContext)
            do {
            try
                self.sharedContext.save()
            } catch let error1 as NSError {
                print(error1)
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotation(pin)
            })
        }
        
    }
    
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "pin"
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdentifier) as? MKPinAnnotationView
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        }
        
        return view
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print(view.annotation?.coordinate)
        let fetchRequest = NSFetchRequest(entityName: "Pin")
    
        let latitudePredicate = NSPredicate(format: "latitude = %@", NSNumber(double: (view.annotation?.coordinate.latitude)!))
        let longitudePredicate = NSPredicate(format: "longitude = %@", NSNumber(double: (view.annotation?.coordinate.longitude)!))
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [latitudePredicate, longitudePredicate])
        var pin: Pin
        do {
            let result = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
            if result.count > 0 {
                pin = result.first! as Pin
                self.performSegueWithIdentifier("showPhotos", sender: pin)
            }
        } catch let error as NSError {
            print(error)
        }
    }
    
    func startOver() {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            let result = try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
            if result.count > 0 {
                for (var i = 0; i < result.count; i++) {
                    for photo: Photo in result[i].pin_photo.allObjects as! [Photo]
                    {
                        sharedContext.deleteObject(photo)
                    }
                    
                    sharedContext.deleteObject(result[i])
                }
            }
        } catch let error as NSError {
            print(error)
        }
    }
}


