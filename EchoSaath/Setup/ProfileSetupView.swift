import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var profileStore = UserProfileStore.shared
    
    @State private var age = ""
    @State private var gender = "Prefer not to say"
    @State private var height = ""
    @State private var weight = ""
    @State private var bloodGroup = "Unknown"
    @State private var address = ""
    @State private var medicalConditions = ""
    
    let genders = ["Male", "Female", "Non-Binary", "Prefer not to say"]
    let bloodGroups = ["Unknown", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    
    enum Field {
        case age, height, weight, address, medicalConditions
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                        
                        Text("Medical Profile")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("This vital information is securely stored locally and used only during emergencies to assist responders.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        
                        // Basic Info
                        HStack(spacing: 16) {
                            GlassTextField(title: "Age", text: $age, icon: "calendar")
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .age)
                            
                            GlassPickerField(title: "Gender", selection: $gender, options: genders, icon: "person.fill")
                        }
                        
                        HStack(spacing: 16) {
                            GlassTextField(title: "Height (cm)", text: $height, icon: "ruler")
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .height)
                            
                            GlassTextField(title: "Weight (kg)", text: $weight, icon: "scalemass")
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .weight)
                        }
                        
                        GlassPickerField(title: "Blood Group", selection: $bloodGroup, options: bloodGroups, icon: "drop.fill")
                        
                        GlassTextField(title: "Home Address", text: $address, icon: "house.fill")
                            .focused($focusedField, equals: .address)
                        
                        // Medical Conditions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pre-existing Medical Conditions (Optional)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("Asthma, Diabetes, Allergies...", text: $medicalConditions, axis: .vertical)
                                .lineLimit(3...5)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .focused($focusedField, equals: .medicalConditions)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Submit Button
                    Button {
                        submitProfile()
                    } label: {
                        Text(AuthViewModel.shared.hasCompletedProfile ? "Save Changes" : "Complete Setup")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            .scaleEffect(focusedField == nil ? 1.0 : 0.98)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .onAppear {
            loadExistingProfile()
        }
    }
    
    private func loadExistingProfile() {
        let saved = profileStore.profile
        age = saved.age
        gender = saved.gender.isEmpty ? "Prefer not to say" : saved.gender
        height = saved.height
        weight = saved.weight
        bloodGroup = saved.bloodGroup.isEmpty ? "Unknown" : saved.bloodGroup
        address = saved.address
        medicalConditions = saved.medicalConditions
    }
    
    private func submitProfile() {
        // Save to store
        let newProfile = UserProfile(
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            bloodGroup: bloodGroup,
            address: address,
            medicalConditions: medicalConditions
        )
        profileStore.updateProfile(newProfile)
        
        // Mark Auth state as completed
        withAnimation {
            AuthViewModel.shared.markProfileCompleted()
        }
        dismiss()
    }
}

// MARK: - Reusable UI Components
struct GlassTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24)
            TextField("", text: $text, prompt: Text(title).foregroundColor(.white.opacity(0.5)))
                .foregroundColor(.white)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct GlassPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24)
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    ProfileSetupView()
}
