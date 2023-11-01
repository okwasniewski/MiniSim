//
//  CustomCommands.swift
//  MiniSim
//
//  Created by Oskar Kwaśniewski on 12/05/2023.
//

import SwiftUI

struct CustomCommands: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            SectionHeader(
                title: "Custom commands",
                subTitle: "Commands will appear in the menubar as clickable buttons."
            )

            Picker("", selection: $viewModel.selectedPlatform) {
                Text("iOS").tag(Platform.ios)
                Text("Android").tag(Platform.android)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 3)

            Table(viewModel.filteredCommands, selection: $viewModel.selection) {
                TableColumn("Icon") { command in
                    Image(systemName: command.icon)
                }
                .width(30)
                TableColumn("Name", value: \.name)
                TableColumn("Command") { command in
                    Text(command.command)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .contextMenu {
                if viewModel.selection != nil {
                    Button("Edit") {
                        viewModel.showForm.toggle()
                    }
                    Divider()
                    Button("Delete") {
                        viewModel.deleteCommands(item: viewModel.selection)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Add new") {
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
        .frame(minWidth: 650, minHeight: 450)
        .padding()
        .sheet(isPresented: $viewModel.showForm) {
            CustomCommandForm(
                command: viewModel.selectedCommand,
                allCommands: viewModel.commands,
                onSubmit: viewModel.handleForm
            )
        }
    }
}

struct CustomCommands_Previews: PreviewProvider {
    static var previews: some View {
        CustomCommands()
    }
}
