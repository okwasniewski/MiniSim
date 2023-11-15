//
//  WelcomeView.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 13/03/2023.
//

import SwiftUI

struct WelcomeView: View {
    var goToNextPage: () -> Void

    var body: some View {
        VStack {
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
            }
            OnboardingHeader(
                title: "Welcome to MiniSim!",
                subTitle: "Thanks for downloading the app"
            )

            OnboardingItem(
                image: "iphone",
                title: "Easily open emulators",
                description: "All your emulators right in your menu bar without opening Android Studio or Xcode."
            )
            .padding(.top, 25)
            OnboardingItem(
                image: "doc.on.clipboard",
                title: "Copy device name and ID",
                description: "Makes it easier to execute custom CLI commands."
            )
            OnboardingItem(
                image: "sparkles",
                title: "And more useful utilities",
                description: "Like: Paste clipboard to emulator, Cold boot and more!"
            )

            OnboardingButton("Continue") {
                goToNextPage()
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView {}
            .frame(width: OnboardingPages.contentWidth, height: OnboardingWindow.height)
    }
}
