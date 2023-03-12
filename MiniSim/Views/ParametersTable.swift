//
//  ParametersTable.swift
//  MiniSim
//
//  Created by Oskar Kwasniewski on 12/03/2023.
//

import SwiftUI


struct Parameter: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var command: String
    var enabled: Bool = true
}

struct ParametersTable: View {
    @State private var parameters: [Parameter] = [.init(title: "", command: "", enabled: false)]
    @State private var selection: Parameter?
    
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
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Android additional launch parameters")
                        .font(.headline)
                        .padding(.bottom, 2)
                    Text("These parameters are passed to every android launch command. \nFor example: Cold boot, Run without audio.")
                        .font(.caption)
                        .opacity(0.3)
                }
                Spacer()
            }
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
                            if let index = parameters.firstIndex(of: $param.wrappedValue)  {
                                parameters.remove(at: index)
                            }
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
                Button {
                    saveData()
                } label: {
                    Text("Save")
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
