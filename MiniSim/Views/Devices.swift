//
//  Devices.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 12/03/2023.
//

import Preferences
import SwiftUI

struct Devices: View {
    var body: some View {
        VStack {
            ParametersTable()
                .padding()
        }
        .frame(minWidth: 650, minHeight: 450)
    }
}

struct Devices_Previews: PreviewProvider {
    static var previews: some View {
        Devices()
    }
}
