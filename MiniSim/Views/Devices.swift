//
//  Devices.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 12/03/2023.
//

import SwiftUI
import Preferences

struct Devices: View {
    var body: some View {
        VStack {
            ParametersTable()
                .padding()
        }
        .frame(minWidth: 450, minHeight: 330)
    }
}

struct Devices_Previews: PreviewProvider {
    static var previews: some View {
        Devices()
    }
}
