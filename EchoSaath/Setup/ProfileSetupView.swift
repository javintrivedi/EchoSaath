import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @StateObject private var profileStore = UserProfileStore.shared
    
    @State private var age = ""
    @State private var gender = "Prefer not to say"
    @State private var height = ""
    @State private var weight = ""
    @State private var bloodGroup = "Unknown"
    @State private var address = ""
    @State private var medicalConditions = ""
    
    // Image picking
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImageData: Data?
    
    let genders = ["Male", "Female", "Non-Binary", "Prefer not to say"]
    let bloodGroups = ["Unknown", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss
    
    enum Field {
        case age, height, weight, address, medicalConditions
    }
    
    var body: some View {
        ZStack {
            Color.appBackgroundPink
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    VStack(spacing: 12) {
                        // Profile Image Picker
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let data = profileImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.pink.opacity(0.3), lineWidth: 2))
                                    .shadow(radius: 5)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    profileImageData = data
                                }
                            }
                        }
                        
                        Text("Medical Profile")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("This vital information is securely stored locally and used only during emergencies to assist responders.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Form Fields
                    VStack(spacing: 16) {
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
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pre-existing Medical Conditions (Optional)")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            
                            TextField("Asthma, Diabetes, Allergies...", text: $medicalConditions, axis: .vertical)
                                .lineLimit(3...5)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground).opacity(0.8))
                                .cornerRadius(12)
                                .focused($focusedField, equals: .medicalConditions)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Button {
                        submitProfile()
                    } label: {
                        Text(AuthViewModel.shared.hasCompletedProfile ? "Save Changes" : "Complete Setup")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.pink.opacity(0.2), radius: 10, y: 5)
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
        .navigationBarTitleDisplayMode(.inline)
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
        profileImageData = saved.profileImageData
    }
    
    private func submitProfile() {
        let newProfile = UserProfile(
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            bloodGroup: bloodGroup,
            address: address,
            medicalConditions: medicalConditions,
            profileImageData: profileImageData
        )
        profileStore.updateProfile(newProfile)
        
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
                .foregroundColor(.secondary)
                .frame(width: 24)
            TextField("", text: $text, prompt: Text(title).foregroundColor(.secondary.opacity(0.6)))
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground).opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
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
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
}
