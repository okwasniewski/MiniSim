//
//  OnboardingHeader.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 09/10/2023.
//

import SwiftUI

struct OnboardingHeader: View {
    var title: String
    var subTitle: String
    
    var body: some View {
        Text(title)
            .font(.largeTitle)
            .padding(.bottom, 5)
        Text(subTitle)
            .multilineTextAlignment(.center)
    }
}
