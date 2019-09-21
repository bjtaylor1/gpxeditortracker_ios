//
//  AppDelegate.swift
//  gpxeditortracker
//
//  Created by Ben Taylor on 15/09/2019.
//  Copyright © 2019 Ben Taylor. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    var locationManager: CLLocationManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        locationManager = CLLocationManager()
        locationManager?.pausesLocationUpdatesAutomatically = true
        
        locationManager?.requestAlwaysAuthorization()
        locationManager?.distanceFilter = 100
        locationManager?.delegate = self;
        
        locationManager?.startUpdatingLocation()
        NSLog("Created location manager")
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation : CLLocation? = locations.last
        if(lastLocation != nil) {
            
            NSLog("didUpdateLocations: %@", lastLocation!)
            saveLocation(location: lastLocation!)
        } else {
            NSLog("didUpdateLocations: last was nil!")
        }
    }
    
    func saveLocation(location: CLLocation) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity")
        do {

            let managedObjectContext = persistentContainer.viewContext
            
            if let records = try managedObjectContext.fetch(fetchRequest) as? [NSManagedObject] {
                
                var locationEntity : NSManagedObject? = nil
                if let firstLocation = records.first {
                    locationEntity = firstLocation
                } else {
                    locationEntity = createRecordForEntity("LocationEntity", inManagedObjectContext: managedObjectContext)
                }
                locationEntity?.setValue(location.coordinate.latitude, forKey: "latitude")
                locationEntity?.setValue(location.coordinate.longitude, forKey: "longitude")
                locationEntity?.setValue(location.timestamp, forKey: "time")
                do {
                    try managedObjectContext.save()
                } catch {
                    NSLog("Failed to save")
                }
                NotificationCenter.default.post(name: .onLocationReceived, object: locationEntity)
            } else {
                NSLog("Haven't got records!");
            }
        } catch {
            NSLog("Unable to fetch records")
        }
    }
    
    private func createRecordForEntity(_ entity: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
        // Helpers
        var result: NSManagedObject?
        
        // Create Entity Description
        let entityDescription = NSEntityDescription.entity(forEntityName: entity, in: managedObjectContext)
        
        if let entityDescription = entityDescription {
            // Create Managed Object
            result = NSManagedObject(entity: entityDescription, insertInto: managedObjectContext)
        }
        
        return result
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "gpxeditortracker")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

