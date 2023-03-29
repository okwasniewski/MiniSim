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
    
    func checkXcode() {
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
    
    var body: some View {
        VStack {
            Spacer()
            Text("Let's check your setup 🛠️")
                .font(.largeTitle)
                .padding(.bottom, 5)
            Text("In order to properly launch simulators,\nyou need to have correct setup.")
                .multilineTextAlignment(.center)
            Spacer()
            VStack (alignment: .leading) {
                Text("Android Studio")
                    .font(.headline)
                    .padding(.bottom, 2)
                if isAndroidSetupCorrect {
                    Label("Looks like everything is running correctly.", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("Something is wrong with your Android setup. Please enter correct ANDROID_HOME path here:", systemImage: "exclamationmark.bubble")
                    AndroidPathInput { isAndroidSetupCorrect = $0 }
                }
            }
            .onboardingContainer()
            .redacted(reason: isLoading ? .placeholder : [])
            
            VStack (alignment: .leading) {
                Text("Xcode")
                    .font(.headline)
                    .padding(.bottom, 2)
                
                if isXcodeSetupCorrect {
                    Label("Looks like everything is running correctly.", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("Something is wrong with your Xcode setup. Please double check if it's installed correctly.", systemImage: "exclamationmark.bubble")
                }
            }
            .onboardingContainer()
            .redacted(reason: isLoading ? .placeholder : [])
            HStack {
                Spacer()
                Button("Re-check") {
                    checkSetup()
                }
                .padding(.trailing, 3)
            }
            
            Spacer()
            
            if isXcodeSetupCorrect && isAndroidSetupCorrect {
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
