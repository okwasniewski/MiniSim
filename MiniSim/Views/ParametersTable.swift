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
    
    var body: some View {
        VStack {
            SectionHeader(
                title: "Android additional launch parameters",
                subTitle: "These parameters are passed to every android launch command. \nFor example: Cold boot, Run without audio etc."
            )
            List {
                HStack {
                    Text("Title")
                        .fontWeight(.semibold)
                        .padding(.leading, 8)
                        .frame(maxWidth: 150, alignment: .leading)
                    Text("Command")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Enabled")
                        .fontWeight(.semibold)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                Divider()
                ForEach($parameters) { $param in
                    VStack {
                        HStack {
                            TextField("Enter title", text: $param.title)
                                .frame(width: 150)
                                .disabled(!$param.enabled.wrappedValue)
                            TextField("Enter command", text: $param.command)
                                .disabled(!$param.enabled.wrappedValue)
                            Spacer()
                            Toggle("", isOn: $param.enabled)
                        }
                        .opacity($param.enabled.wrappedValue ? 1 : 0.5)
                        .padding(.vertical, 1.5)
                    }
                    .contextMenu {
                        Button("Delete") {
                            deleteParameter($param.wrappedValue)
                        }
                    }
                    Divider()
                }
            }
            HStack {
                Button {
                    parameters.append(.init(title: "", command: ""))
                } label: {
                    Image(systemName: "plus")
                }
                Spacer()
                Button("Save") {
                    saveData()
                }
            }
        }
        .onDisappear(perform: saveData)
        .onAppear(perform: loadData)
    }
}

struct ParametersTable_Previews: PreviewProvider {
    static var previews: some View {
        ParametersTable()
    }
}
