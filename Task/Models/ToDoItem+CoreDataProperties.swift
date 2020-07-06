//
//  ToDoItem+CoreDataProperties.swift
//  Task
//
//  Created by Jack on 13/6/20.
//  Copyright © 2020 Jack. All rights reserved.
//
//

import Foundation
import CoreData


extension ToDoItem: Identifiable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoItem> {
        return NSFetchRequest<ToDoItem>(entityName: "ToDoItem")
    }

    @NSManaged public var order: Int
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var notes: String
    @NSManaged public var completed: Bool
    @NSManaged public var flagged: Bool
    @NSManaged public var remindDateOption: Bool
    @NSManaged public var remindDate: Date?
    
}
