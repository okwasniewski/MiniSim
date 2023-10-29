//
//  ParametersTableViewModel.swift
//  MiniSim
//
//  Created by Jan Jaworski on 27/10/2023.
//

import Foundation

extension ParametersTable {
    class ViewModel: ObservableObject {
        @Published var parameters: [Parameter] = []
        @Published var showForm = false
        @Published var selection: Parameter.ID?
        
        var selectedParameter: Parameter? {
            parameters.first(where: { $0.id == selection })
        }
        
        func saveData() {
            let data = try? JSONEncoder().encode(parameters)
            UserDefaults.standard.parameters = data
        }
        
        func loadData() {
            guard let paramData = UserDefaults.standard.parameters else { return }
            if let decodedData = try? JSONDecoder().decode([Parameter].self, from: paramData) {
                parameters = decodedData
            }
        }
        
        func deleteParameters(item: Parameter.ID?) {
            parameters.removeAll(where: { $0.id == item })
            saveData()
        }
        
        func toggleEnabled(item: Parameter.ID?) {
            guard let index = parameters.firstIndex(where: { $0.id == item }) else {
                return
            }
            guard var parameter = parameters.first(where: { $0.id == item }) else {
                return
            }
            parameters.removeAll(where: { $0.id == item })
            parameter.enabled = !parameter.enabled
            parameters.insert(parameter, at: index)
            saveData()
        }
        
        func handleForm(parameter: Parameter, prevParameter: Parameter?) {
            if let prevParameter {
                guard let index = parameters.firstIndex(of: prevParameter) else {
                    return
                }
                parameters.remove(at: index)
                parameters.insert(parameter, at: index)
            }
            else {
                parameters.append(parameter)
            }
            
            saveData()
            showForm = false
        }
    }
}
