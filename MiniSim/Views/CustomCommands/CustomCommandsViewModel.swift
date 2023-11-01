//
//  CustomCommandsViewModel.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/05/2023.
//

import Foundation

extension CustomCommands {
    class ViewModel: ObservableObject {
        @Published var commands: [Command] = []
        @Published var selectedPlatform = Platform.android
        @Published var showForm = false
        @Published var selection: Command.ID?

        var selectedCommand: Command? {
            commands.first { $0.id == selection }
        }

        var filteredCommands: [Command] {
            commands.filter { $0.platform == selectedPlatform }
        }

        func saveData() {
            let data = try? JSONEncoder().encode(commands)
            UserDefaults.standard.commands = data
        }

        func loadData() {
            guard let paramData = UserDefaults.standard.commands else { return }
            if let decodedData = try? JSONDecoder().decode([Command].self, from: paramData) {
                commands = decodedData
            }
        }

        func deleteCommands(item: Command.ID?) {
            commands.removeAll { $0.id == item }
            saveData()
        }

        func handleForm(command: Command, prevCommand: Command?) {
            if let prevCommand {
                guard let index = commands.firstIndex(of: prevCommand) else {
                    return
                }
                commands.remove(at: index)
                commands.insert(command, at: index)
            } else {
                commands.append(command)
            }

            saveData()
            showForm = false
        }
    }
}
