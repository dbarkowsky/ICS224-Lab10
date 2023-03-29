//
//  ServerView.swift
//  SampleServer
//
//  Created by Michael on 2023-02-02.
//

import SwiftUI
import MultipeerConnectivity

struct ServerView.swift: View {
    @StateObject var network = NetworkSupport(browse: true) // browser
    
    @State var message = ""
    @State var networkError = ""
    @State var reply = ""
    @State var selectedPeer : MCPeerID? = nil
    
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
                TextField("Enter a message", text: $message)
                Button(action: {
                    if let message = try? JSONEncoder().encode(message), let peer = selectedPeer {
                        network.send(message: message, to: [peer])
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
