import SwiftUI

struct TrustedContactsView: View {
    struct Contact: Identifiable, Equatable {
        let id = UUID()
        var name: String
        var phone: String
        var relation: String
    }

    @State private var contacts: [Contact] = []
    // Seed with one pre-existing contact to demonstrate removal
    @State private var showingAddSheet = false
    @State private var newName: String = ""
    @State private var newPhone: String = ""
    @State private var newRelation: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 220, height: 220)
                        .offset(x: -120, y: -260)
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 280, height: 280)
                        .offset(x: 140, y: 240)
                }
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2.wave.2.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(
                                    LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .shadow(color: .pink.opacity(0.3), radius: 8, x: 0, y: 6)

                            Text("Trusted Contacts")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.primary)
                                .accessibilityAddTraits(.isHeader)

                            Spacer(minLength: 0)
                        }

                        Text("Add people you trust so EchoSaath can notify them in case of an emergency.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                    // Add Contact button
                    Button {
                        newName = ""
                        newPhone = ""
                        newRelation = ""
                        showingAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Contact")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .pink.opacity(0.25), radius: 10, x: 0, y: 8)
                        .accessibilityLabel("Add trusted contact")
                    }

                    // Contacts list or empty state
                    if contacts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 56, weight: .regular))
                                .foregroundStyle(.pink)
                            Text("No contacts added yet")
                                .font(.headline)
                            Text("Add trusted contacts to keep them informed during emergencies.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
                        )
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(contacts) { contact in
                                HStack(spacing: 12) {
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.pink)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .font(.headline)
                                        if !contact.relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            Text(contact.relation)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(contact.phone)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        withAnimation {
                                            contacts.removeAll { $0.id == contact.id }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "trash")
                                            Text("Remove")
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.red.opacity(0.12))
                                        )
                                        .foregroundStyle(.red)
                                    }
                                    .accessibilityLabel("Remove \(contact.name)")
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
                                )
                            }
                        }
                    }

                    // Primary action button
                    Button {
                        // Mark onboarding complete so AppStartView shows the main app thereafter
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        // Navigate to RootView by replacing the current window's root SwiftUI view
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = scene.windows.first {
                            window.rootViewController = UIHostingController(rootView: RootView())
                            window.makeKeyAndVisible()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Finish Setup")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .pink.opacity(0.25), radius: 10, x: 0, y: 8)
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddContactSheet(
                name: $newName,
                phone: $newPhone,
                relation: $newRelation,
                onCancel: { showingAddSheet = false },
                onSave: {
                    let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedPhone = newPhone.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedRelation = newRelation.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else { return }
                    withAnimation {
                        contacts.append(Contact(name: trimmedName, phone: trimmedPhone, relation: trimmedRelation))
                        showingAddSheet = false
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct AddContactSheet: View {
    @Binding var name: String
    @Binding var phone: String
    @Binding var relation: String

    var onCancel: () -> Void
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Info")) {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    TextField("Relation (e.g., Mother, Friend)", text: $relation)
                }
            }
            .navigationTitle("Add Contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    TrustedContactsView()
}

