import SwiftUI
import AudioToolbox

// MARK: - Route Deviation Alert View
/// Full-screen red alert shown exclusively when the app detects a route
/// deviation AFTER the 10-day learning phase is complete.
/// The user has 60 seconds to confirm they are safe before SOS is sent.
struct RouteDeviationAlertView: View {
    @ObservedObject private var processor = EventProcessor.shared
    @State private var timeRemaining: Int = 60
    @State private var timer: Timer?
    @State private var pulse = false
    @State private var shake = false

    var body: some View {
        ZStack {
            // Background gradient — urgent deep red
            LinearGradient(
                colors: [Color(red: 0.7, green: 0.0, blue: 0.0), Color(red: 0.4, green: 0.0, blue: 0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated pulse rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(0.12 - Double(i) * 0.03), lineWidth: 50)
                    .scaleEffect(pulse ? 1.8 + Double(i) * 0.5 : 1.0)
                    .opacity(pulse ? 0 : 0.5)
                    .animation(
                        .easeOut(duration: 1.8).repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.4),
                        value: pulse
                    )
            }

            VStack(spacing: 0) {

                // MARK: Top section — icon + headline
                VStack(spacing: 20) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 8)
                        .scaleEffect(pulse ? 1.06 : 1.0)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

                    Text("Route Change Detected")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("You appear to be on an unfamiliar path.\nAre you safe?")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.top, 70)
                .padding(.horizontal, 28)

                Spacer()

                // MARK: Countdown ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 14)
                        .frame(width: 160, height: 160)

                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / 60.0)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)

                    VStack(spacing: 2) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("seconds")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Text("SOS will be sent to your contacts automatically.")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 32)

                Spacer()

                // MARK: Action buttons
                VStack(spacing: 14) {
                    // Safe button
                    Button {
                        resolveAlert(isSafe: true)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title3.bold())
                            Text("Yes, I Am Safe")
                                .font(.title3.bold())
                        }
                        .foregroundColor(Color(red: 0.6, green: 0.0, blue: 0.0))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                    }

                    // Danger button
                    Button {
                        resolveAlert(isSafe: false)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sos")
                                .font(.title3.bold())
                            Text("I Need Help — Send SOS")
                                .font(.title3.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            pulse = true
            timeRemaining = 60
            startCountdown()
            triggerHaptic()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    // MARK: - Helpers

    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                if timeRemaining <= 10 {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            } else {
                // Auto-escalate: user didn't respond → treat as danger
                resolveAlert(isSafe: false)
            }
        }
    }

    private func resolveAlert(isSafe: Bool) {
        timer?.invalidate()
        timer = nil
        processor.resolveRouteDeviation(isSafe: isSafe)
    }

    private func triggerHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
}

#Preview {
    RouteDeviationAlertView()
}
