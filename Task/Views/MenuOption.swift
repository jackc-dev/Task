//
//  MenuOption.swift
//  Task
//
//  Created by Jack on 14/6/20.
//  Copyright © 2020 Jack. All rights reserved.
//

import SwiftUI

struct MenuOption: View {
    
    @Binding var showMenuOption: Bool
    var sortList: () -> Void
    var hideCompleted: () -> Void
    
    // Dark Mode
    @State private var lightModeToggle: Bool = UserDefaults.standard.bool(forKey: "LightMode") {
        didSet{
            SceneDelegate.shared?.window!.overrideUserInterfaceStyle = self.lightModeToggle ? .dark : .light
            UserDefaults.standard.set(self.lightModeToggle, forKey: "LightMode")
        }
    }
    
    var body: some View {
        VStack (spacing: 15){
            Button(action: {
                self.lightModeToggle.toggle()
            } ) {
                Text(self.lightModeToggle ? "Switch to Light Mode" : "Switch to Dark Mode")
                    .padding(.horizontal)
                Image(systemName: self.lightModeToggle ? "sun.min.fill" : "moon.stars.fill" )
                    .resizable()
                    .frame(width: 25, height: 25)
            }
            .padding(.top)
            .frame(maxWidth: .infinity)
            
            Divider()
            
            Button(action: {
                self.sortList()
                self.showMenuOption.toggle()
            } ) {
                Text("Sort Alphabetically")
            }
            .frame(maxWidth: .infinity)
            .padding()
            
            Button(action: {
                self.hideCompleted()
                self.showMenuOption.toggle()
            } ) {
                Text(UserDefaults.standard.bool(forKey: "HideCompleted") ? "Show Completed" : "Hide Completed")
            }
            .frame(maxWidth: .infinity)
            .padding()
            
            
        }
        .background(Color("BG_Sub"))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 50)
        .edgesIgnoringSafeArea(.bottom)
    }
}
