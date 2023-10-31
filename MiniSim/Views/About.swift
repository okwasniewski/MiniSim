//
//  About.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import SwiftUI
import Sparkle

struct About: View {
    private let updaterController: SPUStandardUpdaterController
    @Environment (\.openURL) private var openURL

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

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
            Button {
                updaterController.updater.checkForUpdates()
            } label: {
                Label("Check for updates", systemImage: "gear")
            }
            .padding(.bottom, 10)

            HStack {
                Button("GitHub") {
                    openURL(URL(string: "https://github.com/okwasniewski/MiniSim")!)
                }
                Button("Buy me a coffee") {
                    openURL(URL(string: "https://github.com/sponsors/okwasniewski")!)
                }
            }.padding(.bottom)
            Link("Created by Oskar Kwaśniewski", destination: URL(string: "https://github.com/okwasniewski")!)
                .font(.caption)
        }
        .frame(minWidth: 650, minHeight: 450)
    }
}
