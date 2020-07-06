//
//  ToDoItemDetailView.swift
//  Task
//
//  Created by Jack on 13/6/20.
//  Copyright © 2020 Jack. All rights reserved.
//

import SwiftUI
import Foundation
import UserNotifications

struct ToDoItemDetailView: View {
    @Binding var showToDoDetail: Bool
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @State var title = ""
    @State var notes = ""
    @ObservedObject var toDoItem: ToDoItem
    
    @State private var isFlagged = false
    @State private var withExistingNotification = false
    @State private var remindDateOption = false
    @State private var remindDate: Date = Date()
    @State private var showingAlert = false
    
     var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("New Task", text: $title)
                    TextField("Notes", text: $notes)
                }
                Section {
                    Toggle(isOn: $remindDateOption) {
                        Text("Remind me on a day")
                    }
                    self.remindDateOption
                        ? DatePicker("Alarm", selection: $remindDate, in: Date()...)
                        : nil
                }
                Section {
                    Toggle(isOn: $isFlagged) {
                        Text("Flagged")
                    }
                }
            }
            .navigationBarItems(trailing: Button(
                action: {
                    self.toDoItem.title = self.title.isEmpty ? "New Task" : self.title
                    self.toDoItem.notes = self.notes
                    self.toDoItem.flagged = self.isFlagged
                    self.toDoItem.remindDateOption = self.remindDateOption
                    self.toDoItem.remindDate = self.toDoItem.remindDateOption ? self.remindDate : nil
                    
                    if (self.toDoItem.remindDateOption) {
                        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                            if settings.authorizationStatus == .authorized {
                                self.addNotification()
                                self.saveItem()
                            } else if settings.authorizationStatus == .denied {
                                self.showingAlert = true
                            } else if settings.authorizationStatus == .notDetermined {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                    if success {
                                        self.addNotification()
                                        self.saveItem()
                                    } else if !success {
                                        self.showingAlert = true
                                    } else if let error = error {
                                        print(error.localizedDescription)
                                    }
                                }
                            }
                        }
                    } else {
                        // Remove notification
                        if (self.withExistingNotification) {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.toDoItem.id.uuidString])
                        }
                        self.saveItem()
                    }
                },
                label: { Text("Done").bold() }
            )
            )
            .navigationBarTitle("Details")
            .onAppear(perform: {
                self.title = self.toDoItem.title == "New Task" ? "" :self.toDoItem.title
                self.notes = self.toDoItem.notes
                
                if self.toDoItem.remindDateOption {
                    if self.toDoItem.remindDate ?? Date() >= Date() {
                        self.remindDateOption = self.toDoItem.remindDateOption
                        self.withExistingNotification = self.toDoItem.remindDateOption
                        self.remindDate = self.toDoItem.remindDate ?? Date()
                    }
                }
                
                self.isFlagged = self.toDoItem.flagged
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Permission Not Granted"), message: Text("Kindly allow notifications in Setting before turning on reminder."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func addNotification() {
        let content = UNMutableNotificationContent()
        content.title =  self.toDoItem.title
        content.subtitle = self.toDoItem.notes
        content.sound = UNNotificationSound.default

        // Configure the recurring date.
        let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,], from: self.remindDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: self.toDoItem.id.uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
    
    func saveItem() {
        do {
            try self.managedObjectContext.save()
            print("Item saved.")
            self.showToDoDetail = false
        } catch {
            print(error.localizedDescription)
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}
