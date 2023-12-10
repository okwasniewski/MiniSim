//
//  SetupItemView.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 10/10/2023.
//

import SwiftUI

struct SetupItemView<Content: View>: View {
    var imageName: String
    var title: String
    var subTitle: String?

    @ViewBuilder let content: Content?

    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .padding(.trailing, 5)
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .padding(.bottom, 2)
                    if let subTitle {
                        Text(subTitle)
                            .font(.caption)
                    }
                }
                Spacer()
                if let content {
                    content
                }
            }
            Spacer()
        }
        .onboardingContainer()
    }
}
