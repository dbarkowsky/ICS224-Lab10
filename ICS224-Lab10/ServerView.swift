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
    @State var pictureInterval : Float = 1
    var images : [UIImage] = [UIImage(imageLiteralResourceName: "kingdedede"), UIImage(imageLiteralResourceName: "waddlede")]
    
    var pics = ["car", "hare", "tortoise"]
    
    var body: some View {
        VStack {
            if selectedPeer == nil {
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
                    Slider(value: $pictureInterval, in: 0...1, step: 1)
                }
                
                TextField("Enter a message", text: $message)
                Button(action: {
                    if let message = try? JSONEncoder().encode(pics[Int(pictureInterval)]), let peer = selectedPeer {
                        network.send(message: images[Int(pictureInterval)].pngData()!, to: [peer])
                    }
                }, label: {
                    Image(systemName: "paperplane")
                })
                Text(reply)
                    .multilineTextAlignment(.leading)
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
}
