//
//  SetupPreferences.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 09/10/2023.
//

import SwiftUI

struct SetupPreferences: View {
    var goToNextPage: () -> Void
    @AppStorage(UserDefaults.Keys.enableiOSSimulators, store: .standard) var enableiOSSimulators: Bool = true
    @AppStorage(UserDefaults.Keys.enableAndroidEmulators, store: .standard) var enableAndroidEmulators: Bool = true

    var body: some View {
        VStack {
            Spacer()
            OnboardingHeader(
                title: "Tooling ⚙️",
                subTitle: """
                          If you want to use Minisim for launching only Android or
                          only iOS simulators you can tweak it here.
                          """
            )
            Spacer()
            VStack {
                SetupItemView(imageName: "xcode", title: "Xcode", subTitle: "iOS Simulators") {
                    Toggle("", isOn: $enableiOSSimulators)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                SetupItemView(imageName: "android_studio", title: "Android Studio", subTitle: "Android Emulators") {
                    Toggle("", isOn: $enableAndroidEmulators)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            Spacer()
            if enableiOSSimulators || enableAndroidEmulators {
                OnboardingButton("Continue", action: goToNextPage)
            }

            Spacer()
        }
    }
}

#Preview {
    SetupPreferences(goToNextPage: {})
}
