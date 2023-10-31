//
//  OnboardingItem.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 13/03/2023.
//

import SwiftUI

struct OnboardingItem: View {
    var image: String
    var title: String
    var description: String

    var body: some View {
        HStack {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 20)
                .padding(.trailing, 5)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
            }
            Spacer()
        }.padding(.bottom)
    }
}

struct OnboardingItem_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingItem(
            image: "sparkles",
            title: "And more useful utilities",
            description: "Like: Paste clipboard to emulator, Cold boot and more!"
        )
    }
}
