//
//  ViewModifiers.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 06/02/2023.
//

import SwiftUI

struct DescriptionText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.leading, 15)
            .font(.caption)
            .opacity(0.3)
    }
}

struct OnboardingContainer: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(colorScheme == .light ? Color.white : Color.black.opacity(0.4))
            .foregroundColor(colorScheme == .light ? .black : .white)
            .cornerRadius(12)
    }
}

extension View {
    func descriptionText() -> some View {
        modifier(DescriptionText())
    }
    
    func onboardingContainer() -> some View {
        modifier(OnboardingContainer())
    }
}
