//
//  ParametersTable.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 12/03/2023.
//

import SwiftUI

struct ParametersTable: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            SectionHeader(
                title: "Android additional launch parameters",
                subTitle: """
                          These parameters are passed to every android launch command.
                          \nFor example: Cold boot, Run without audio etc.
                          """
            )
            Table(viewModel.parameters, selection: $viewModel.selection) {
                TableColumn("Title", value: \.title)
                    .width(80)
                TableColumn("Command", value: \.command)
                TableColumn("Enabled") { toggle in
                    Text("\(String(toggle.enabled))")
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
                        viewModel.deleteParameter(item: viewModel.selection)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Add New") {
                    viewModel.selection = nil
                    viewModel.showForm.toggle()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showForm) {
            ParametersTableForm(
                parameter: viewModel.selectedParameter,
                allParameters: viewModel.parameters,
                onSubmit: viewModel.handleForm
            )
        }
    }
}

struct ParametersTable_Previews: PreviewProvider {
    static var previews: some View {
        ParametersTable()
    }
}
