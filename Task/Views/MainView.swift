//
//  mainView.swift
//  Task
//
//  Created by Jack on 13/6/20.
//  Copyright © 2020 Jack. All rights reserved.
//

import SwiftUI

struct MainView: View {
    // Persistence
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(
        entity: ToDoItem.entity(),
        sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)])
    var toDoItems: FetchedResults<ToDoItem>
    
    var filteredItems: [ToDoItem] {
        return toDoItems.filter({ (item) -> Bool in
            UserDefaults.standard.bool(forKey: "HideCompleted")
                ? (item.completed ? false : true)
                : true // Display all items
        })
    }
    
    // Search Bar
    @State private var searchText = ""
    @State private var showCancelButton: Bool = false
    
    @State private var selectedItem: ToDoItem?
    @State private var editingTitle = ""
    @State private var showToDoDetail = false
    
    // Action Sheet
    @State private var showMenuOption = false
    
    // Hide Completed
    @State private var filterByIncomplete: Bool = UserDefaults.standard.bool(forKey: "HideCompleted") {
        didSet{
            UserDefaults.standard.set(self.filterByIncomplete, forKey: "HideCompleted")
        }
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .trailing) {
                NavigationView {
                    VStack {
                        // Top Toolbar
                        HStack {
                            self.toDoItems.count > 0 ? SearchBar(text: $searchText).animation(.default) : nil
                            self.searchText == "" && toDoItems.count > 0
                                ? EditButton()
                                    .padding(.trailing)
                                    .transition(.move(edge: .trailing))
                                    .animation(.default)
                                : nil
                            self.searchText != ""
                                ? Button(action: {
                                    self.searchText = ""
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    }) { Text("Clear") }
                                    .padding(.trailing)
                                    .transition(.move(edge: .trailing))
                                    .animation(.default)
                                : nil
                            
                        }
                        .padding(.bottom, -15) // Padding between top toolbar and list
                        
                        List {
                            ForEach(filteredItems.filter({
                                (self.searchText.isEmpty
                                    ? true
                                    : $0.title.contains(searchText) || $0.notes.contains(searchText))
                                })
                            ) { item in
                                HStack {
                                    Button(action: { self.updateCompletion(item: item) }) {
                                        Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                    }.buttonStyle(BorderlessButtonStyle())
                                    
                                    if item.title == "" {
                                        TextField("Title", text: self.$editingTitle)
                                        
                                    } else {
                                        Text("\(item.title)")
                                            .frame(maxWidth: .infinity, alignment: .leading) // Better than using Spacer() as it cause performance issue during editing mode
                                        item.flagged
                                            ? Button(action: { self.updateFlag(item: item) }) {
        //                                        Image(systemName: item.flagged ? "flag.fill" : "flag")
                                                Image(systemName: "flag.fill")
                                                    .resizable()
                                                    .frame(width: 12.0, height: 12.0)
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            : nil
                                    }
                                }
                                .contentShape(Rectangle()) // Make whole row tappable
                                .onTapGesture {
                                    self.showToDoDetail = true
                                    self.selectedItem = item
                                }
                            }
                            .onDelete(perform: deleteItem)
                            .onMove(perform: moveItem)
                            .onDisappear(perform: saveItems)
                        }
                        .sheet(isPresented: self.$showToDoDetail) {
                            ToDoItemDetailView(
                            showToDoDetail: self.$showToDoDetail,
                            toDoItem: self.selectedItem ?? ToDoItem()).environment(\.managedObjectContext, self.managedObjectContext)
                        }
                    }
                    .navigationBarTitle("All Tasks")

                }
        
                // Bottom Toolbar
                HStack {
                    Button(action: addNewItem ) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                            Text("New Task")
                        }
                        .padding()
                    }
                    Spacer()
                    Button(action: { self.showMenuOption.toggle() } ) {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .frame(width: 25, height: 25)
                        .padding()
                    }
                }
            }
            VStack { // Pop-up Menu
                Spacer()
                MenuOption(showMenuOption: self.$showMenuOption, sortList: sortItem, hideCompleted: hideCompleted)
                    .offset(y: self.showMenuOption ? 0 : UIScreen.main.bounds.height)
            }
            .background(self.showMenuOption ? Color.black.opacity(0.3) : Color.clear).edgesIgnoringSafeArea(.all)
            .onTapGesture {
                self.showMenuOption.toggle()
            }
        }.animation(.default)
    }

    
    func addNewItem() {
        let newToDoItem = ToDoItem(context: managedObjectContext)
        newToDoItem.id = UUID()
        newToDoItem.title = "New Task"
        newToDoItem.order = (toDoItems.last?.order ?? 0) + 1
        self.editingTitle = ""
        saveItems()
    }
    
    func saveItems() {
        do {
            try managedObjectContext.save()
        } catch {
            print(error)
        }
    }
    
    func deleteItem(at offsets: IndexSet) {
        let index = offsets[offsets.startIndex]
        let deleteItem: ToDoItem = self.filteredItems[index]
        for (_, item) in self.toDoItems.enumerated(){
            if (item.id == deleteItem.id) {
                if (item.remindDateOption) {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
                }
                self.managedObjectContext.delete(item)
//                saveItems()
                break
            }
        }
    }
    
    func moveItem(indexSet: IndexSet, destination: Int) {
        let source = indexSet.first!
        
        if source < destination {
            var startIndex = source + 1
            let endIndex = destination - 1
            var startOrder = toDoItems[source].order
            while startIndex <= endIndex {
                toDoItems[startIndex].order = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            toDoItems[source].order = startOrder
        } else if destination < source {
            var startIndex = destination
            let endIndex = source - 1
            var startOrder = toDoItems[destination].order + 1
            let newOrder = toDoItems[destination].order
            while startIndex <= endIndex {
                toDoItems[startIndex].order = startOrder
                startOrder = startOrder + 1
                startIndex = startIndex + 1
            }
            toDoItems[source].order = newOrder
        }
        saveItems()
    }
    
    func updateFlag(item: ToDoItem) {
        managedObjectContext.performAndWait {
            item.flagged.toggle()
            saveItems()
        }
    }
    
    func updateCompletion(item: ToDoItem) {
        managedObjectContext.performAndWait {
            item.completed.toggle()
            saveItems()
        }
    }
    
    func sortItem() {
        let toDoList = toDoItems.sorted { $0.title < $1.title }
        
        var i = 1
        for item in toDoList {
            item.order = i
            i += 1
        }
        saveItems()
    }
    
    func hideCompleted() {
        self.filterByIncomplete.toggle()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return MainView().environment(\.managedObjectContext, context)
    }
}
