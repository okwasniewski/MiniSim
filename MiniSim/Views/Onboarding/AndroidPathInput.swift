//
//  AndroidPathInput.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 19/03/2023.
//

import SwiftUI

struct AndroidPathInput: View {
    @State private var androidPath = ""
    @State private var androidHomeError: Error?
    var onSave: ((_ isPathCorrect: Bool) -> Void)?

    init(_ onSave: ((_ isPathCorrect: Bool) -> Void)? = nil) {
        self.onSave = onSave
    }

    func onAppear() {
        if let androidHome = try? ADB.getAndroidHome() {
            androidPath = androidHome
        }
    }

    func savePath() {
        do {
            if try ADB.checkAndroidHome(path: androidPath) {
                if let onSave { onSave(true) }
                androidHomeError = nil
                UserDefaults.standard.androidHome = androidPath
            }
        } catch {
            if let onSave { onSave(false) }
            androidHomeError = error
        }
    }

    var body: some View {
        VStack {
            TextField("Android path", text: $androidPath)
            if androidHomeError != nil {
                Text(androidHomeError?.localizedDescription ?? "")
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button("Save path") {
                    savePath()
                }
            }
        }
        .onAppear(perform: onAppear)
    }
}

struct AndroidPathInput_Previews: PreviewProvider {
    static var previews: some View {
        AndroidPathInput()
    }
}
