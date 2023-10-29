//
//  ParametersTable.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 12/03/2023.
//

import SwiftUI

struct ParametersTable: View {
    @State private var parameters: [Parameter] = [.init(title: "", command: "", enabled: false)]
    
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
    
    func deleteParameter(_ parameter: Parameter) {
        NSApp.keyWindow?.makeFirstResponder(nil)
        if let index = parameters.firstIndex(of: parameter)  {
            parameters.remove(at: index)
        }
    }
    
    @StateObject private var viewModel: ViewModel = ViewModel()
    
    var body: some View {
        VStack {
            SectionHeader(
                title: "Android additional launch parameters",
                subTitle: "These parameters are passed to every android launch command. \nFor example: Cold boot, Run without audio etc."
            )
            Table(viewModel.parameters, selection: $viewModel.selection) {
                TableColumn("Title", value: \.title)
                    .width(80)
                TableColumn("Command", value: \.command)
                TableColumn("Enabled") {
                    Text("\(String($0.enabled))")
                }
            }
            .contextMenu {
                if viewModel.selection != nil {
                    Button(viewModel.selectedParameter?.enabled == true ? "Disable" : "Enable") {
                        viewModel.toggleEnabled(item: viewModel.selectedParameter?.id)
                    }
                    Divider()
                    Button("Edit") {
                        viewModel.showForm.toggle()
                    }
                    Divider()
                    Button("Delete") {
                        viewModel.deleteParameters(item: viewModel.selection)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Add New") {
                    viewModel.selection = nil
                    viewModel.showForm.toggle()
                }.buttonStyle(.borderedProminent)
                    .keyboardShortcut("n", modifiers: .command)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showForm) {
            ParametersTableForm(parameter: viewModel.selectedParameter, allParameters: viewModel.parameters, onSubmit: viewModel.handleForm)
        }
    }
}

struct ParametersTable_Previews: PreviewProvider {
    static var previews: some View {
        ParametersTable()
    }
}
