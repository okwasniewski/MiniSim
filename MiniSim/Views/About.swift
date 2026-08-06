//
//  About.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 28/01/2023.
//

import AcknowList
import Sparkle
import SwiftUI

struct About: View {
  private let updaterController: SPUStandardUpdaterController
  @Environment(\.openURL) private var openURL
  @State private var isAcknowledgementsListPresented = false

  init() {
    updaterController = SPUStandardUpdaterController(
      // Do not start Sparkle while the About view is being created. Starting
      // it schedules automatic checks and can trigger macOS App Management
      // authorization for the updater installer on every app launch.
      startingUpdater: false,
      updaterDelegate: nil,
      userDriverDelegate: nil
    )
  }

  let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  private let bottomPadding: Double = 10
  private let minFrameWidth: Double = 650
  private let minFrameHeight: Double = 450

  var body: some View {
    VStack {
      Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
      Text("MiniSim")
        .font(.title)
      if let appVersion {
        Text("Version: \(appVersion)")
          .padding(.bottom, bottomPadding)
      }
      Button {
        updaterController.startUpdater()
        updaterController.updater.checkForUpdates()
      } label: {
        Label("Check for updates", systemImage: "gear")
      }
      .padding(.bottom, bottomPadding)

      Button("Acknowledgements") {
        isAcknowledgementsListPresented.toggle()
      }

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
    .sheet(isPresented: $isAcknowledgementsListPresented) {
      NavigationView {
        AcknowListSwiftUIView(acknowList: AcknowParser.defaultPackages()!)
          .toolbar {
            ToolbarItem(placement: .automatic) {
              Button("Close") {
                isAcknowledgementsListPresented = false
              }
            }
          }
      }
      .frame(minHeight: 450)
    }
    .frame(minWidth: minFrameWidth, minHeight: minFrameHeight)
  }
}
