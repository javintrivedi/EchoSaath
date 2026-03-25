import SwiftUI

struct EditContactView: View {
    let contact: TrustedContact
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var phone: String

    init(contact: TrustedContact) {
        self.contact = contact
        self._name = State(initialValue: contact.name)
        self._phone = State(initialValue: contact.phoneNumber)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
            }
            .navigationTitle("Edit Contact")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        let updated = TrustedContact(
                            id: contact.id,
                            name: name.trimmingCharacters(in: .whitespaces),
                            phoneNumber: phone.trimmingCharacters(in: .whitespaces)
                        )
                        TrustedContactsStore.shared.update(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                              phone.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EditContactView(contact: TrustedContact(name: "John Doe", phoneNumber: "+1234567890"))
}
