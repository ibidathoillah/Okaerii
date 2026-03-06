import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress indicators
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.okaerizenPrimary : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.spring(), value: currentPage)
                }
            }
            .padding(.top, 24)
            
            // Content
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                OnboardingPage(
                    icon: "🍵",
                    title: "Welcome to Okaerii",
                    description: "Your personal ambient soundscape companion. Create focus, relaxation, or sleep environments right from your menu bar.",
                    features: [
                        FeatureInfo(icon: "sparkles", title: "Zen Atmosphere", description: "Minimalist design for maximum focus.")
                    ]
                )
                .tag(0)
                
                // Page 2: Features
                OnboardingPage(
                    icon: "🎧",
                    title: "Immersive Audio",
                    description: "High-fidelity spatial soundscapes that help you block out distractions and find your flow.",
                    features: [
                        FeatureInfo(icon: "music.note.list", title: "Curated Scenes", description: "Birds, Rain, Cafe, and more."),
                        FeatureInfo(icon: "slider.horizontal.3", title: "Custom Mixes", description: "Blend multiple layers to your liking.")
                    ]
                )
                .tag(1)
                
                // Page 3: Getting Started
                OnboardingPage(
                    icon: "🚀",
                    title: "Ready to Go?",
                    description: "Okaerii lives in your menu bar. Just click the tea cup icon to start your journey.",
                    features: [
                        FeatureInfo(icon: "menubar.arrow.up.rectangle", title: "Quick Access", description: "Always one click away."),
                        FeatureInfo(icon: "keyboard", title: "Global Shortcuts", description: "Control playback from anywhere.")
                    ]
                )
                .tag(2)
            }
            .tabViewStyle(.automatic)
            .animation(.easeInOut, value: currentPage)
            
            // Footer Navigation
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        finishOnboarding()
                    }
                }) {
                    Text(currentPage < 2 ? "Next" : "Get Started")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.okaerizenPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .frame(width: 450, height: 550)
        .background(Color.okaerizenBackground)
        .tag(999)
    }
    
    private func finishOnboarding() {
        isPresented = false
        // Close the window
        NSApp.windows.first { $0.contentView?.subviews.first?.tag == 999 }?.close()
        if let window = NSApp.windows.first(where: { $0.title == "Welcome to Okaerii" }) {
            window.close()
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let features: [FeatureInfo]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated Icon
            ZStack {
                Circle()
                    .fill(Color.okaerizenPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Text(icon)
                    .font(.system(size: 70))
            }
            
            // Text Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                
                Text(description)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }
            
            // Features
            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.title) { feature in
                    HStack(spacing: 16) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(Color.okaerizenPrimary)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text(feature.description)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.top, 16)
            
            Spacer()
        }
    }
}

struct FeatureInfo {
    let icon: String
    let title: String
    let description: String
}
