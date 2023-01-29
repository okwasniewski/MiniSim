//
//  About.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import SwiftUI

struct About: View {
    @Environment (\.openURL) private var openURL
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    var body: some View {
        VStack {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
            Text("MiniSim")
                .font(.title)
            if let appVersion {
                Text("Version: \(appVersion)")
                    .padding(.bottom, 10)
            }
            HStack {
                Button("Github") {
                    openURL(URL(string: "https://github.com/okwasniewski/MiniSim")!)
                }
                Button("Buy me a coffee") {
                    openURL(URL(string: "https://github.com/sponsors/okwasniewski")!)
                }
            }.padding(.bottom)
            Link("Created by Oskar Kwaśniewski", destination: URL(string: "https://github.com/okwasniewski")!)
                .font(.caption)
        }
        .frame(minWidth: 450, minHeight: 300)
    }
}
