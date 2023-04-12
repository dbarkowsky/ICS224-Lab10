//
//  ContentView.swift
//  ICS224-Lab10-Server
//
//  Created by ICS 224 on 2023-03-29.
//

import SwiftUI

struct ContentView: View {
    @StateObject var camera : CameraController = CameraController()
    @State var isServer : Bool = false
    var body: some View {
        VStack{
            if isServer {
                ServerView(camera: camera)

            } else {
                ClientView()
            }
            Spacer()
            Button(action: {
                isServer.toggle()
            }){
                Text("Switch to \(isServer ? "Client" : "Server")")
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
