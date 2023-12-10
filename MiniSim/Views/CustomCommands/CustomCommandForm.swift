//
//  CustomCommandForm.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 15/05/2023.
//

import CodeEditor
import SwiftUI
import SymbolPicker

struct CustomCommandForm: View {
    var command: Command?
    var allCommands: [Command]
    var onSubmit: (_ command: Command, _ prevCommand: Command?) -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @StateObject private var viewModel = ViewModel()

    private let codeEditorCornerRadius: Double = 6
    private let variablesOpacity: Double = 0.9
    private let iconPickerImageFrameWidth: Double = 20
    private let iconPickerImagePadding: Double = 3
    private let iconPickerButtonCornerRadious: Double = 12
    private let formMinWidth: Double = 550
    private let formMinHeight: Double = 400

    var body: some View {
        Form {
            TextField("Name", text: $viewModel.commandName)
            HStack(alignment: .top) {
                CodeEditor(
                    source: $viewModel.command,
                    language: .bash,
                    theme: colorScheme == .dark ? .atelierSavannaDark : .atelierSavannaLight,
                    flags: [.selectable, .editable, .smartIndent]
                )
                .cornerRadius(codeEditorCornerRadius)
                GroupBox("Variables") {
                    VStack(alignment: .leading) {
                        ForEach(viewModel.availableVariables, id: \.self) { variable in
                            Button(variable.rawValue) {
                                NSPasteboard.general.copyToPasteboard(text: variable.rawValue)
                            }
                            .buttonStyle(.plain)
                            .opacity(variablesOpacity)
                            .font(.system(.caption, design: .monospaced))
                            .help(variable.description + " - click to copy.")
                            .padding(.vertical, 1)
                        }
                    }
                    .font(.subheadline)
                    .onChange(of: viewModel.needsBootedDevice) { _ in
                        viewModel.updateAvailableVariables()
                    }
                    .onChange(of: viewModel.platform) { _ in
                        viewModel.updateAvailableVariables()
                    }
                }
            }
            HStack {
                Text("Icon")
                Spacer()
                Button {
                    viewModel.iconPickerPresented = true
                } label: {
                    Image(systemName: viewModel.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconPickerImageFrameWidth)
                        .padding(iconPickerImagePadding)
                }
                .background(.regularMaterial)
                .cornerRadius(iconPickerButtonCornerRadious)
            }
            Picker("Platform", selection: $viewModel.platform) {
                Text("iOS").tag(Platform.ios)
                Text("Android").tag(Platform.android)
            }

            Toggle(isOn: $viewModel.needsBootedDevice) {
                Text("Needs booted device")
            }
            .help("Determines if command needs a booted device to execute.")
            .toggleStyle(.switch)
            .disabled(viewModel.bootsDevice)

            Toggle(isOn: $viewModel.bootsDevice) {
                Text("Boots device")
            }
            .help("Determines if executed command boots device. This command will be hidden on booted devices.")
            .toggleStyle(.switch)
            .disabled(viewModel.needsBootedDevice)

            HStack {
                HStack {
                    Button("Cancel") {
                        dismiss()
                        viewModel.clearForm()
                    }
                }
                Spacer()
                Button(command != nil ? "Update" : "Add") {
                    onSubmit(
                        Command(
                            name: viewModel.commandName,
                            command: viewModel.command,
                            icon: viewModel.icon,
                            platform: viewModel.platform,
                            needBootedDevice: viewModel.needsBootedDevice,
                            bootsDevice: viewModel.bootsDevice
                        ),
                        command
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
        .frame(minWidth: formMinWidth, minHeight: formMinHeight)
        .sheet(isPresented: $viewModel.iconPickerPresented) {
            SymbolPicker(symbol: $viewModel.icon)
        }
        .onAppear {
            if let command {
                viewModel.onAppear(
                    commandName: command.name,
                    command: command.command,
                    needsBootedDevice: command.needBootedDevice,
                    bootsDevice: command.bootsDevice ?? false,
                    platform: command.platform,
                    icon: command.icon
                )
            }
            viewModel.onAppear(allCommands: allCommands, isUpdating: command != nil)
        }
    }
}
