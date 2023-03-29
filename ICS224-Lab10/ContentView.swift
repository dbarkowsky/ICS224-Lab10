//
//  ContentView.swift
//  ICS224-Lab10-Server
//
//  Created by ICS 224 on 2023-03-29.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            ClientView()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
