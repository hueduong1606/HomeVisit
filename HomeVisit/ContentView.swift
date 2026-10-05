//  ContentView.swift
//  HomeVisit

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "house.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("HomeVisit")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
