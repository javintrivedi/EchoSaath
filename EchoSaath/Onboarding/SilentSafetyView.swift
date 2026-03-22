//
//  SilentSafetyView.swift
//  EchoSaath
//
//  Created by Javin Trivedi on 11/03/26.
//

import SwiftUI

struct SilentSafetyView: View {
    @State private var appear = false
    @State private var nextPressed = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles with subtle motion
            GeometryReader { proxy in
                let size = proxy.size
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 220, height: 220)
                        .offset(x: -120 + (appear ? -6 : 0), y: -260 + (appear ? -4 : 0))
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: appear)
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 280, height: 280)
                        .offset(x: 140 + (appear ? 6 : 0), y: 240 + (appear ? 4 : 0))
                        .animation(.easeInOut(duration: 1.2).delay(0.2).repeatForever(autoreverses: true), value: appear)
                }
                .frame(width: size.width, height: size.height, alignment: .center)
            }
            .ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 72, weight: .semibold))
                        .foregroundStyle(.pink)
                        .padding(14)
                        .background(
                            LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .opacity(0.15)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Silent Safety")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)

                    Text("SOS button triggers discreet alerts and monitoring even when you can’t speak.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 12) {
                    featureRow(icon: "hand.raised.fill", title: "One-tap SOS", subtitle: "Trigger help instantly from the lock screen or app.")
                    featureRow(icon: "mic.slash.fill", title: "Discreet mode", subtitle: "Operate silently to avoid drawing attention.")
                    featureRow(icon: "message.and.waveform.fill", title: "Auto-messages", subtitle: "Send prewritten alerts with your location.")
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

                Spacer(minLength: 0)

                NavigationLink(destination: EvidenceView()) {
                    HStack(spacing: 8) {
                        Text("Next")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .pink.opacity(0.25), radius: 10, x: 0, y: 8)
                    .scaleEffect(nextPressed ? 0.98 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: nextPressed)
                    .accessibilityLabel("Continue to the next step")
                    .accessibilityHint("Learn how evidence capture works")
                }
                .padding(.horizontal)
            }
            .padding()
            .onAppear { appear = true }
        }
        .navigationTitle("Silent Safety")
    }
    
    @ViewBuilder
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.pink)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator).opacity(0.6), lineWidth: 0.5)
        )
    }
}

#Preview {
    NavigationStack {
        SilentSafetyView()
    }
}
