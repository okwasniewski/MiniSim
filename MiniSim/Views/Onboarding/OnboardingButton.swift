//
//  OnboardingButton.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 16/03/2023.
//

import SwiftUI

struct OnboardingButton: View {
    var text: String
    var action: () -> Void
    
    init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(Font.headline.weight(.semibold))
                .padding(.vertical, 12)
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(13)
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingButton_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingButton("Hey") {
            
        }
    }
}
