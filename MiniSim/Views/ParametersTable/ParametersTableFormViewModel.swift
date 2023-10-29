//
//  ParametersTableFormViewModel.swift
//  MiniSim
//
//  Created by Jan Jaworski on 27/10/2023.
//

import Foundation

extension ParametersTableForm {
    class ViewModel: ObservableObject {
        @Published var title = ""
        @Published var command = ""
        @Published var enabled = true
        
        var allParameters: [Parameter] = []
        var isUpdating: Bool = false
        
        func onAppear(title: String = "", command: String = "", enabled: Bool = true) {
            self.title = title
            self.command = command
            self.enabled = enabled
        }
        
        func onAppear(allCommands: [Parameter], isUpdating: Bool = false) {
            self.allParameters = allCommands
            self.isUpdating = isUpdating
        }
        
        var disableForm: Bool {
            let hasDuplicatedName = !isUpdating && allParameters.contains(where: { $0.title.lowercased() == title.lowercased() })
            return title.isEmpty || command.isEmpty || hasDuplicatedName
        }
        
        func clearForm() {
            title = ""
            command = ""
            enabled = true
        }
    }
}
