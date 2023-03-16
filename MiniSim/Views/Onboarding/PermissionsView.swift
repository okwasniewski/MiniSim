//
//  PermissionsView.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/03/2023.
//

import SwiftUI
import UserNotifications

struct PermissionsView: View {
    @State private var hasA11yAccess = false
    @State private var hasNotificationsAccess = false
    @Environment(\.controlActiveState) var controlActiveState
    
    func requestNotifications() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization()) ?? false
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Permissions")
                .font(.largeTitle)
                .padding(.bottom, 5)
            Text("MiniSim needs access to system APIs that require your permission.")
                .multilineTextAlignment(.center)
            Spacer()
            VStack (alignment: .leading) {
                Label("Accessibility", systemImage: "figure.roll")
                    .font(.headline)
                    .padding(.bottom, 2)
                HStack {
                    Text("App uses accessibility api in order to focus devices instead of trying to open them one more time")
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    if !hasA11yAccess {
                        Button("Request") {
                            hasA11yAccess = AccessibilityElement.hasA11yAccess(prompt: true)
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onboardingContainer()
            
            VStack (alignment: .leading) {
                Label("Notifications", systemImage: "bell.fill")
                    .font(.headline)
                    .padding(.bottom, 2)
                HStack {
                    Text("App shows local notifications when action is completed.")
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    if !hasNotificationsAccess {
                        Button("Request") {
                            Task {
                                hasNotificationsAccess = await requestNotifications()
                            }
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onboardingContainer()
            
            Spacer()
            OnboardingButton("Start using MiniSim!") {
                NSApplication.shared.mainWindow?.close()
                UserDefaults.standard.isOnboardingFinished = true
            }
            Spacer()
        }
        .onAppear {
            hasA11yAccess = AccessibilityElement.hasA11yAccess(prompt: false)
        }
        .onChange(of: controlActiveState) { newValue in
            if newValue != .key {
                return
            }
            
            hasA11yAccess = AccessibilityElement.hasA11yAccess(prompt: false)
            Task {
                hasNotificationsAccess = await requestNotifications()
            }
        }
    }
}
