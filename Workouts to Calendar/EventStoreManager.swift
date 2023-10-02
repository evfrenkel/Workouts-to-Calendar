//
//  EventStoreManager.swift
//  Calendar Test
//
//  Created by Evan Frenkel on 10/25/16.
//  Copyright © 2016 Evan Frenkel. All rights reserved.
//

import Foundation
import EventKit
import HealthKit

class EventStoreManager {
    private let defaults = UserDefaults.init()
    
    private let eventStore = EKEventStore()
    //private var addedWorkouts = Set<String>()
    private var eventStoreAuthorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: EKEntityType.event)
    private var calendar: EKCalendar? {
        didSet {
            debugPrint("EventStoreManager calendar set")
            if calendar != nil {
                defaults.set(calendar!.calendarIdentifier, forKey: calendarDefaultsKey)
                debugPrint("UserDefaults Calendar ID Saved")
            }
        }
    }
    
    func askForCalendarAuth() {
        eventStore.requestFullAccessToEvents()
        {
            (success, error) in
            if success {
                self.eventStoreAuthorizationStatus = EKAuthorizationStatus.fullAccess
                print("EKAuthorizationStatus.writeOnly")
            } else if let error = error {
                print(error)
            } else {
                self.eventStoreAuthorizationStatus = EKAuthorizationStatus.denied
                print("EKAuthorizationStatus.denied")
            }
        }
    }
    
    func hasCalendarAuth() -> Bool {
        switch self.eventStoreAuthorizationStatus {
        case EKAuthorizationStatus.denied,
             EKAuthorizationStatus.restricted:
            return false
        case EKAuthorizationStatus.notDetermined:
            self.askForCalendarAuth()
            return false
        default:
            return true
        }
    }
        
    func getSourceAccount() -> EKSource? {
        if let sourceIdentifier = defaults.string(forKey: sourceDefaultsKey) {
            return eventStore.source(withIdentifier: sourceIdentifier)
        }
        return nil
    }
    private func initCalendar() {
        debugPrint("EventStoreManager init calendar")
        let source = eventStore.source(withIdentifier: defaults.string(forKey: sourceDefaultsKey)!)
        let calendar = EKCalendar.init(for: EKEntityType.event, eventStore: eventStore)
        calendar.title = "Workouts to Calendar App"
        calendar.source = source
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            self.calendar = calendar
            debugPrint("📅 new calendar created")
        }
        catch {
            debugPrint("🚫 initCalendar() -> " + error.localizedDescription)
        }
    }
    func needNewCalendar() -> Bool {
        if let calendarID = defaults.string(forKey: calendarDefaultsKey) {
            calendar = eventStore.calendar(withIdentifier: calendarID)
        }
        if calendar == nil {
            initCalendar()
            return true
        }
        return false
    }
    func commitEvents(queryResults: [HKSample]) {
        debugPrint("Adding \(queryResults.count) workouts...")
        for sample in queryResults {
            commitEvent(workout: sample as! HKWorkout)
        }
        debugPrint("Done adding")
    }
    
    private func commitEvent(workout: HKWorkout) {
            let event = EKEvent.init(eventStore: eventStore)
            event.startDate = workout.startDate
            event.endDate = workout.endDate
            event.calendar = calendar!
            event.title = StringGetter.getTitle(workout: workout)
            do {
                try eventStore.save(event, span: EKSpan.thisEvent)
            }
            catch {
                debugPrint(error)
            }
    }
    
    func deleteCalendar() {
        debugPrint("Deleting Calendar")
        
        if calendar != nil {
            do {
                try eventStore.removeCalendar(calendar!, commit: true)
                calendar = nil
            }
            catch {
                debugPrint(error)
            }
        }
        
        defaults.setValue([], forKey: addedWorkoutsDefaultsKey)
    }
    
    init() {
        print("👶 EventStoreManager")
    }
}

class StringGetter {
    class func getTitle(workout: HKWorkout) -> String {
        let type = workout.workoutActivityType
        
        var title = ""
        
        switch type {
        case .running:
            title = "🏃 Run"
        case .yoga:
            title = "🧘🤸‍♂️ Yoga"
        case .cycling:
            title = "🚴 Cycle"
        case .swimming:
            title = "🏊 Swim"
        case .dance:
            title = "🕺 Dance"
        case .walking:
            title = "🚶 Walk"
        case .stairs:
            title = "Stair Workout"
        case .hiking:
            title = "🚶 Hike"
        case .rowing:
            title = "🚣 Row"
        default:
            title = "🏃 Workout"
        }
        
        if let energy = workout.totalEnergyBurned?.doubleValue(for: HKUnit.largeCalorie()) {
            title += " (\(Int(round(energy)))cal"
            
            if let distance = workout.totalDistance?.doubleValue(for: HKUnit.mile()) {
                let thousandthsDistance = round(distance*100)/100
                title += ", " + thousandthsDistance.description + "mi"
            }
            title += ")"
        }

        return title
    }
}
