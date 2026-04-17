import SwiftUI
import AVFoundation
import UIKit
import AudioToolbox

struct EmergencyCountdownView: View {
    @ObservedObject var processor = EventProcessor.shared
    @AppStorage("alertCountdownDuration") private var countdownDuration: Int = 10
    @State private var timeRemaining = 10
    @State private var timer: Timer?
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        ZStack {
            // High-alert red background
            Color.red
                .ignoresSafeArea()
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 40)
                        .scaleEffect(processor.isAlerting ? 2 : 1)
                        .opacity(processor.isAlerting ? 0 : 1)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: processor.isAlerting)
                )
            
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Emergency Triggered")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Sending SOS to trusted contacts in...")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Countdown Circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 15)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / 10.0)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)
                    
                    Text("\(timeRemaining)")
                        .font(.system(size: 80, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // I'm Safe Button
                Button {
                    cancelAlert()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                        Text("I AM SAFE")
                            .fontWeight(.black)
                    }
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
            .padding()
        }
        .onAppear {
            timeRemaining = countdownDuration
            startCountdown()
            playAlertSound()
        }
        .onDisappear {
            stopAlertSound()
        }
    }
    
    private func startCountdown() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            } else {
                executeSOS()
            }
        }
    }
    
    private func cancelAlert() {
        timer?.invalidate()
        timer = nil
        stopAlertSound()
        withAnimation {
            processor.cancelCountdown()
        }
    }
    
    private func executeSOS() {
        timer?.invalidate()
        timer = nil
        stopAlertSound()
        processor.finalizeAlert()
    }
    
    private func playAlertSound() {
        // In a real app, we'd bundle an alert.mp3. Using system sound for now.
        AudioServicesPlaySystemSound(1005) // Alarm sound
    }
    
    private func stopAlertSound() {
        // Stop logic if using AVAudioPlayer
    }
}

#Preview {
    EmergencyCountdownView()
}
