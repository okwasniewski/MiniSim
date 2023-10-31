//
//  SetupView.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/03/2023.
//

import SwiftUI
import ShellOut

struct SetupView: View {
    var goToNextPage: () -> Void
    @State private var isLoading = true
    @State private var isXcodeSetupCorrect: Bool = true
    @State private var isAndroidSetupCorrect: Bool = true

    @AppStorage(UserDefaults.Keys.enableiOSSimulators, store: .standard) var enableiOSSimulators: Bool = true
    @AppStorage(UserDefaults.Keys.enableAndroidEmulators, store: .standard) var enableAndroidEmulators: Bool = true

    var canContinue: Bool {
        let enableiOS = enableiOSSimulators ? isXcodeSetupCorrect : true
        let enableAndroid = enableAndroidEmulators ? isAndroidSetupCorrect : true
        return enableiOS && enableAndroid
    }

    func checkXcode() {
        if !enableiOSSimulators {
            return
        }
        isXcodeSetupCorrect = DeviceService.checkXcodeSetup()
    }

    func checkAndroidStudio() {
        do {
            UserDefaults.standard.androidHome = try DeviceService.checkAndroidSetup()
        } catch {
            isAndroidSetupCorrect = false
        }
    }

    func checkSetup() {
        isLoading = true
        checkAndroidStudio()
        checkXcode()
        isLoading = false
    }

    var setupItemSubTitle: String {
        isXcodeSetupCorrect ?
        "Everything is running correctly." :
        "Something is wrong with your setup. Please check if Xcode is installed correctly."
    }

    var body: some View {
        VStack {
            Spacer()
            OnboardingHeader(
                title: "Let's check your setup 🛠️",
                subTitle: "In order to properly launch simulators,\nyou need to have correct setup."
            )
            Spacer()

            if enableiOSSimulators {
                SetupItemView(
                    imageName: "xcode",
                    title: "Xcode",
                    subTitle: setupItemSubTitle
                ) {

                }
                .redacted(reason: isLoading ? .placeholder : [])
            }

            if enableAndroidEmulators {
                SetupItemView(
                    imageName: "android_studio",
                    title: "Android Studio",
                    subTitle: isAndroidSetupCorrect ?
                    "Everything is running correctly." :
                        "Something is wrong with your Android setup. Please enter correct ANDROID_HOME path here:"
                ) {
                    if !isAndroidSetupCorrect {
                        AndroidPathInput { isAndroidSetupCorrect = $0 }
                    }
                }
                .redacted(reason: isLoading ? .placeholder : [])
            }
            HStack {
                Spacer()
                Button("Re-check") {
                    checkSetup()
                }
                .padding(.trailing, 3)
            }

            Spacer()

            if canContinue {
                OnboardingButton("Continue") {
                    goToNextPage()
                }
                Spacer()
            }
        }
        .onAppear(perform: checkSetup)
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(goToNextPage: {})
            .padding(25)
            .frame(width: 400, height: 600)
    }
}
