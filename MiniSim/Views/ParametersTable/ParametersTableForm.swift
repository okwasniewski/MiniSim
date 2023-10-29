//
//  ParametersTableForm.swift
//  MiniSim
//
//  Created by Jan Jaworski on 27/10/2023.
//

import SwiftUI
import SymbolPicker
import CodeEditor


struct ParametersTableForm: View {
    var parameter: Parameter?
    var allParameters: [Parameter]
    var onSubmit: (_ parameter: Parameter, _ prevParameter: Parameter?) -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var viewModel: ViewModel = ViewModel()
    
    var body: some View {
        Form {
            TextField("Title", text: $viewModel.title)
            HStack(alignment: .top) {
                CodeEditor(
                    source: $viewModel.command,
                    language: .bash,
                    theme: colorScheme == .dark ? .atelierSavannaDark : .atelierSavannaLight,
                    flags: [.selectable, .editable, .smartIndent]
                )
                .cornerRadius(6)
            }
            Toggle(isOn: $viewModel.enabled, label: {
                Text("Enabled")
            })
            .help("Determines if command is enabled.")
            .toggleStyle(.switch)
            
            HStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                        viewModel.clearForm()
                    }
                }
                Spacer()
                Button(parameter != nil ? "Update" : "Add") {
                    onSubmit(
                        Parameter(
                            title: viewModel.title,
                            command: viewModel.command,
                            enabled: viewModel.enabled
                        ),
                        parameter
                    )
                    viewModel.clearForm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.disableForm)
                .keyboardShortcut("s", modifiers: .command)
            }
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 550, minHeight: 400)
        .onAppear {
            if let parameter {
                viewModel.onAppear(
                    title: parameter.title,
                    command: parameter.command,
                    enabled: parameter.enabled
                )
            }
            viewModel.onAppear(allCommands: allParameters, isUpdating: parameter != nil)
        }
    }
}
