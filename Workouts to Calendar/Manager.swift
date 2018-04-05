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
        if defaults.bool(forKey: syncDefaultsKey) {
            var anchor: HKQueryAnchor?
            
            if !eventStoreManager.needNewCalendar(), let anchorCoded = defaults.object(forKey: anchorDefaultsKey) as? Data {
                anchor = NSKeyedUnarchiver.unarchiveObject(with: anchorCoded) as? HKQueryAnchor
            }
            
            let anchoredQuery = HKAnchoredObjectQuery.init(type: HKWorkoutType.workoutType(),
                                                           predicate: nil,
                                                           anchor: anchor,
                                                           limit: Int(HKObjectQueryNoLimit),
                                                           resultsHandler: self.anchoredQueryResultsHandler)
            healthStore.execute(anchoredQuery)
        }
    }
    private func anchoredQueryResultsHandler(query: HKAnchoredObjectQuery, added: [HKSample]?, deleted: [HKDeletedObject]?, anchor: HKQueryAnchor?, error: Error?) {
        
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: anchor as Any), forKey: anchorDefaultsKey)
        
        if let added = added {
            eventStoreManager.commitEvents(queryResults: added)
        }
        observerCompletion!()
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
