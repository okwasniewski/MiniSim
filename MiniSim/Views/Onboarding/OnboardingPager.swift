//
//  OnboardingPager.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/03/2023.
//

import SwiftUI

enum OnboardingPages: CaseIterable {
    case welcome
    case setupPreferences
    case setup
    case permissions
    
    @ViewBuilder
    func view(goToNextPage: @escaping () -> Void) -> some View {
        switch self {
        case .welcome:
            WelcomeView(goToNextPage: goToNextPage)
        case .setupPreferences:
            SetupPreferences(goToNextPage: goToNextPage)
        case .setup:
            SetupView(goToNextPage: goToNextPage)
        case .permissions:
            PermissionsView()
        }
    }
}

struct OnboardingPager: View {
    @State private var currentPage: OnboardingPages = .welcome
    var pageIndex: Int {
        OnboardingPages.allCases.firstIndex(of: currentPage) ?? 0
    }
    
    func goToNextPage() {
        let allPages = OnboardingPages.allCases
        if let index = allPages.firstIndex(of: currentPage), index + 1 < allPages.count {
            currentPage = allPages[index + 1]
        }
    }
    
    func goToPreviousPage() {
        let allPages = OnboardingPages.allCases
        if let index = allPages.firstIndex(of: currentPage), index > 0 {
            currentPage = allPages[index - 1]
        }
    }
    
    var body: some View {
        ZStack {
            if (pageIndex > 0) {
                Button("Go Back") {
                    goToPreviousPage()
                }
                .buttonStyle(.link)
                .position(x: 35, y: 20)
            }
            VStack {
                ForEach(OnboardingPages.allCases, id: \.self) { page in
                    if currentPage == page {
                        page.view(goToNextPage: goToNextPage)
                            .frame(maxWidth: 350, alignment: .center)
                    }
                }
            }
        }
        .frame(minWidth: 450, minHeight: 550)
        .background(BlurredView())
    }
}

struct OnboardingPager_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPager()
    }
}
