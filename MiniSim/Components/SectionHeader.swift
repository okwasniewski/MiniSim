//
//  SectionHeader.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 02/06/2023.
//

import SwiftUI

struct SectionHeader: View {
    var title: String
    var subTitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 2)
                Text(subTitle)
                    .font(.caption)
                    .opacity(0.3)
            }
            Spacer()
        }
    }
}
