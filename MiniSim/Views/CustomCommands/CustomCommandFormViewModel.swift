//
//  CustomCommandFormViewModel.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/05/2023.
//

import Foundation

extension CustomCommandForm {
    class ViewModel: ObservableObject {
        @Published var availableVariables = Variables.common
        @Published var commandName = ""
        @Published var command = ""
        @Published var needsBootedDevice = false
        @Published var bootsDevice = false
        @Published var platform = Platform.android
        @Published var icon = "info"

        @Published var iconPickerPresented = false

        var allCommands: [Command] = []
        var isUpdating = false

        func onAppear(
            commandName: String = "",
            command: String = "",
            needsBootedDevice: Bool = false,
            bootsDevice: Bool = false,
            platform: Platform = Platform.android,
            icon: String = "info",
            iconPickerPresented: Bool = false
        ) {
            self.commandName = commandName
            self.command = command
            self.needsBootedDevice = needsBootedDevice
            self.bootsDevice = bootsDevice
            self.platform = platform
            self.icon = icon
            self.iconPickerPresented = iconPickerPresented
        }

        func onAppear(allCommands: [Command], isUpdating: Bool = false) {
            self.allCommands = allCommands
            self.isUpdating = isUpdating
            self.updateAvailableVariables()
        }

        var disableForm: Bool {
            let containsCommand = allCommands
                .map { $0.name.lowercased() }
                .contains { $0 == commandName.lowercased() }
            let hasDuplicatedName = !isUpdating && containsCommand
            return commandName.isEmpty || command.isEmpty || hasDuplicatedName
        }

        func clearForm() {
            commandName = ""
            command = ""
            needsBootedDevice = false
            icon = "info"
        }

        func updateAvailableVariables() {
            var variables = Variables.common
            variables.append(contentsOf: platform == .ios ? Variables.ios : Variables.android)
            availableVariables = variables
            if needsBootedDevice && platform == .android {
               availableVariables.append(Variables.adbId)
            }
        }
    }
}
