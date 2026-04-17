import Foundation
import SwiftUI
import Combine

// MARK: - User Profile Model
public struct UserProfile: Codable, Equatable {
    var age: String
    var gender: String
    var height: String
    var weight: String
    var bloodGroup: String
    var address: String
    var medicalConditions: String
    var profileImageData: Data? // Added for profile picture
    
    public init(
        age: String = "",
        gender: String = "",
        height: String = "",
        weight: String = "",
        bloodGroup: String = "",
        address: String = "",
        medicalConditions: String = "",
        profileImageData: Data? = nil
    ) {
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.bloodGroup = bloodGroup
        self.address = address
        self.medicalConditions = medicalConditions
        self.profileImageData = profileImageData
    }
}

// MARK: - User Profile Store
final class UserProfileStore: ObservableObject {
    static let shared = UserProfileStore()
    
    @Published var profile: UserProfile {
        didSet {
            save()
        }
    }
    
    private let storageKey = "echosaath_user_profile"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfile()
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func updateProfile(_ newProfile: UserProfile) {
        self.profile = newProfile
    }
}
