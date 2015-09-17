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
        
        setInitialMapView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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
    }
    
    func addPinToMap(gestureRecogizer: UILongPressGestureRecognizer) {
        let coordinate = mapView.convertPoint(gestureRecogizer.locationInView(self.mapView), toCoordinateFromView: self.mapView)
        let pin = Pin(coordinate.latitude, coordinate.longitude, NSSet(), sharedContext)
        sharedContext.save()
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView.addAnnotation(pin)
        })
        
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
}


