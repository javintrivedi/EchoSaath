import SwiftUI

struct WelcomeView: View {

    var body: some View {

        VStack {

            Spacer()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("EchoSaath")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Because every alert matters.")
                .foregroundColor(.gray)

            Spacer()

            NavigationLink(destination: WhyEchoSaathView()) {
                Text("Get Started")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .cornerRadius(12)
            }
            .padding()

        }
        .padding()
        .background(Color(red: 0.96, green: 0.86, blue: 0.90))
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
