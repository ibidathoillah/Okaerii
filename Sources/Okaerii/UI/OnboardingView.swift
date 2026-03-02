import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.okaerizenPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Text("🍵")
                    .font(.system(size: 60))
            }
            .padding(.bottom, 8)
            
            // Text
            VStack(spacing: 12) {
                Text("Welcome to Okaerii")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Your personal ambient soundscape companion. Create focus, relaxation, or sleep environments right from your menu bar.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }
            
            // Features Grid
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "music.note.list", title: "Curated Scenes", description: "Choose from handcrafted soundscapes.")
                FeatureRow(icon: "slider.horizontal.3", title: "Custom Mixes", description: "Create your own perfect atmosphere.")
                FeatureRow(icon: "menubar.arrow.up.rectangle", title: "Always Ready", description: "Lives in your menu bar for quick access.")
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
            
            // Button
            Button(action: {
                // Set flag
                isPresented = false
                
                // Close the window containing this view
                NSApp.windows.first { $0.contentView?.subviews.first?.tag == 999 }?.close()
                // Fallback close
                if let window = NSApp.windows.first(where: { $0.title == "Welcome to Okaerii" }) {
                    window.close()
                }
            }) {
                Text("Get Started")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.okaerizenPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.okaerizenBackground)
        // Tag to identify this window content
        .tag(999)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.okaerizenPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
