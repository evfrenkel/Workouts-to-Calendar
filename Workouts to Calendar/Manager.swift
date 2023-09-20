//
//  HealthKitManager.swift
//  Calendar Test
//
//  Created by Evan Frenkel on 10/23/16.
//  Copyright © 2016 Evan Frenkel. All rights reserved.
//

import Foundation
import HealthKit

/// Manages Healthkit and Eventkit
class Manager {
    private let healthStore = HKHealthStore()
    private let defaults = UserDefaults.init()
    
    private func doQuery() {
        guard defaults.bool(forKey: syncDefaultsKey) else {
            // Exit if sync is not enabled
            return
        }

        var anchor: HKQueryAnchor?

        if !eventStoreManager.needNewCalendar(), let anchorCoded = defaults.data(forKey: anchorDefaultsKey) {
            do {
                anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: anchorCoded)
            } catch {
                // Handle the error here
                print("Error unarchiving anchor: \(error)")
            }
        }

        // Calculate the start date (6 months ago from the current date)
       let calendar = Calendar.current
       let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date())
       
       // Create a predicate to filter workouts
       let predicate = HKQuery.predicateForSamples(withStart: sixMonthsAgo, end: Date(), options: .strictStartDate)
           
        let anchoredQuery = HKAnchoredObjectQuery(
            type: HKWorkoutType.workoutType(),
            predicate: predicate,
            anchor: anchor,
            limit: HKObjectQueryNoLimit,
            resultsHandler: self.anchoredQueryResultsHandler
        )

        healthStore.execute(anchoredQuery)
    }
    
    private func anchoredQueryResultsHandler(query: HKAnchoredObjectQuery, added: [HKSample]?, deleted: [HKDeletedObject]?, anchor: HKQueryAnchor?, error: Error?) {
        if let error = error {
            // Handle the error here
            print("Anchored query error: \(error)")
        } else {
            if let anchor = anchor, let anchorData = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) {
                defaults.set(anchorData, forKey: anchorDefaultsKey)
            }
            
            if let added = added {
                eventStoreManager.commitEvents(queryResults: added)
            }
            
            observerCompletion?()
        }
    }
    
    private var observerCompletion: HKObserverQueryCompletionHandler?
    
    // MARK: - Public
    // Public Interface
    
    let eventStoreManager = EventStoreManager()
    
    var observerQuery: HKObserverQuery?
    func startObserving() {
        healthStore.requestAuthorization(toShare: nil, read: [HKObjectType.workoutType()]) {
            (success, error) in
            if success {
                self.observerQuery = HKObserverQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil) {
                    (query, completion, error) in
                    
                    self.observerCompletion = completion
                    
                    print("\n🙏 Observer Query Start:")
                    if error != nil {
                        debugPrint("\(error!)")
                    }
                    self.doQuery()
                }
                self.healthStore.execute(self.observerQuery!)
                self.healthStore.enableBackgroundDelivery(for: HKObjectType.workoutType(), frequency: .immediate) {
                    (success, error) in
                    
                    if success {
                        debugPrint("Enabled background delivery")
                    }
                    else {
                        debugPrint("\(error!.localizedDescription)")
                    }
                }
            }
        }
    }
    func stopObserving() {
        defaults.setValue(nil, forKey: anchorDefaultsKey)
        eventStoreManager.deleteCalendar()
        if let observerQuery = self.observerQuery {
            healthStore.stop(observerQuery)
        }
        healthStore.disableAllBackgroundDelivery() {
            (success, error) in
            if success == false {
                print(error!.localizedDescription)
            }
        }
    }
    
    init() {
        print("👶 HealthKitManager")
    }
}
