//
//  AddContactView.swift
//  EchoSaath
//
//  Created by BLACKBOXAI.
//

import SwiftUI

struct AddContactView: View {
    @Binding var name: String
    @Binding var phone: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(name: Binding<String>, phone: Binding<String>, onSave: @escaping () -> Void) {
        self._name = name
        self._phone = phone
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Phone Number", text: $phone)
                    .keyboardType(.phonePad)
            }
            .navigationTitle("Add Contact")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddContactView(name: .constant(""), phone: .constant(""), onSave: {})
}

