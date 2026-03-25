import SwiftUI

struct TrustedContactsView: View {
    @StateObject private var store = TrustedContactsStore.shared
    @State private var showingAddContact = false
    @State private var newContactName = ""
    @State private var newContactPhone = ""
    @State private var editingContact: TrustedContact?
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// When true, this is part of onboarding and "Continue" navigates to auth.
    /// When false, accessed from Settings — just shows contacts management.
    var isOnboarding: Bool = true

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.94, blue: 0.96).ignoresSafeArea()

            if store.contacts.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.contacts) { contact in
                        contactRow(contact)
                    }
                    .onDelete(perform: deleteContacts)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Trusted Contacts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showingAddContact = true
                    } label: {
                        Image(systemName: "plus")
                    }

                    if isOnboarding {
                        NavigationLink(destination: AuthView()) {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                        .disabled(store.contacts.isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            AddContactView(
                name: $newContactName,
                phone: $newContactPhone,
                onSave: saveNewContact
            )
        }
        .sheet(item: $editingContact) { contact in
            EditContactView(contact: contact)
        }
    }

    // MARK: - Contact Row
    private func contactRow(_ contact: TrustedContact) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(
                    LinearGradient(colors: [.pink.opacity(0.7), .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(contact.name.prefix(1)).uppercased())
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                editingContact = contact
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.pink)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Trusted Contacts")
                .font(.title3.bold())

            Text("Add at least one contact who will be\nnotified during emergencies.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddContact = true
            } label: {
                Label("Add Contact", systemImage: "plus")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Actions
    private func saveNewContact() {
        let trimmedName = newContactName.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = newContactPhone.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else { return }

        let contact = TrustedContact(name: trimmedName, phoneNumber: trimmedPhone)
        store.add(contact)
        newContactName = ""
        newContactPhone = ""
        showingAddContact = false
    }

    private func deleteContacts(at offsets: IndexSet) {
        offsets.map { store.contacts[$0] }.forEach { store.remove($0) }
    }
}

#Preview {
    NavigationStack {
        TrustedContactsView()
    }
}
