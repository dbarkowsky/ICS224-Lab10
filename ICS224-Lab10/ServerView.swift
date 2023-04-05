//
//  ServerView.swift
//  SampleServer
//
//  Created by Michael on 2023-02-02.
//

import SwiftUI
import MultipeerConnectivity

struct ServerView: View {
    @StateObject var network = NetworkSupport(browse: true) // browser
    
    @State var message = ""
    @State var networkError = ""
    @State var reply = ""
    @State var selectedPeer : MCPeerID? = nil
    @State var pictureInterval : Double = 2.0
    @State var cameraOn : Bool = false
    @State var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    @State var pictureNum : Int = 0
    var images : [UIImage] = [UIImage(imageLiteralResourceName: "kingdedede"), UIImage(systemName: "tortoise")!, UIImage(systemName: "ladybug")!]
    
    
    var pics = ["car", "hare", "tortoise"]
    
    var body: some View {
        VStack {
            if selectedPeer == nil || !cameraOn {
                Text("Choose a connection:")
                Button(action: {
                    if (selectedPeer != nil){
                        cameraOn = true
                    }
                }){
                    Text("Start Camera")
                }
                List(network.peers, id: \.self.hashValue) {
                    peer in
                    Button(action: {
                        networkError = ""
                        do {
                            try network.contact(peerID: peer, request: Request(placeholder: "SomePlaceholder"))
                            selectedPeer = peer
                        }
                        catch let error {
                            networkError = error.localizedDescription
                        }
                    }) {
                        Text(peer.displayName)
                    }
                }
            }
            else {
                
                HStack{
                    Text("\(Int(pictureInterval))")
                    Slider(value: $pictureInterval, in: 0...2, step: 1)
                }.onAppear {
                    Task { await runCamera() }
                }
                .onReceive(timer){
                    timerInput in
                    Task { await runCamera() }
                }
                Button(action:{
                    selectedPeer = nil
                    cameraOn = false
                }){
                    Text("Stop Camera")
                }
            }
            
            Text(networkError)
        }
        .onChange(of: network.incomingMessage) { newValue in
            if let decodedMessage = try? JSONDecoder().decode(String.self, from: network.incomingMessage) {
                reply = decodedMessage
            }
        }
        .onChange(of: network.peers) { newValue in
            if network.peers.filter({$0 == selectedPeer}).count == 0 {
                selectedPeer = nil
            }
        }
        .padding()
    }
    
    func runCamera(){
        Task {
            print("in runCamera")
            if let message = try? JSONEncoder().encode(pics[Int(pictureInterval)]), let peer = selectedPeer {
                network.send(message: images[Int(pictureNum % images.count)].pngData()!, to: [peer]) // TODO: put in camera info
            }
            pictureNum += 1
        }
    }
    
}


