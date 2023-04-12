//
//  ContentView.swift
//  ICS224-Lab10-Server
//
//  Created by ICS 224 on 2023-03-29.
//

import SwiftUI

struct ContentView: View {
    @StateObject var camera : CameraController = CameraController()
    var body: some View {
        TabView {
            ClientView()
                .tabItem {
                    Label("Client", systemImage: "tortoise")
                }
            ServerView(camera: camera)
                .tabItem {
                    Label("Server", systemImage: "hare")
                }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
