import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms of Service")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Last updated: April 18, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                VStack(spacing: 20) {
                    termSection(
                        number: "1",
                        title: "Acceptance",
                        content: "By using EchoSaath, you agree to these terms. If you do not agree, please do not use the application."
                    )
                    
                    termSection(
                        number: "2",
                        title: "Emergency Responsibility",
                        content: "EchoSaath is a safety tool, not a replacement for professional emergency services. While we strive for 100% reliability, we are not responsible for delivery failures caused by network issues, carrier delays, or device settings."
                    )
                    
                    termSection(
                        number: "3",
                        title: "System Requirements",
                        content: "For optimal safety, you must keep location services set to 'Always' and ensure background refresh is enabled. Disabling these will significantly impact the app's ability to protect you."
                    )
                    
                    termSection(
                        number: "4",
                        title: "User Conduct",
                        content: "The SOS feature should only be used in genuine emergencies or for controlled testing. Abuse of emergency services through the app is strictly prohibited."
                    )
                    
                    termSection(
                        number: "5",
                        title: "Modifications",
                        content: "We reserve the right to modify these terms at any time. Continued use of the app constitutes acceptance of any changes."
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.appBackgroundPink.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func termSection(number: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.pink)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
