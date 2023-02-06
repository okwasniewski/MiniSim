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

extension View {
    func descriptionText() -> some View {
        modifier(DescriptionText())
    }
}
