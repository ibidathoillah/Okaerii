import SwiftUI

struct LayerToggleRow: View {
    @Binding var layer: AudioLayer
    var onToggle: () -> Void
    var onVolumeChange: (Float) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox/Toggle
            Button(action: {
                layer.isEnabled.toggle()
                onToggle()
            }) {
                Image(systemName: layer.isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(layer.isEnabled ? Color.okaerizenPrimary : .secondary)
            }
            .buttonStyle(.plain)
            
            // Icon & Name
            HStack(spacing: 6) {
                Image(systemName: layer.type.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                
                Text(layer.type.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(layer.isEnabled ? .primary : .secondary)
            }
            
            Spacer()
            
            // Volume Slider (only if enabled)
            if layer.isEnabled {
                Slider(
                    value: Binding(
                        get: { layer.volume },
                        set: {
                            layer.volume = $0
                            onVolumeChange($0)
                        }
                    ),
                    in: 0...1
                )
                .controlSize(.mini)
                .frame(width: 80)
                .tint(Color.okaerizenPrimary)
            }
        }
        .padding(4)
        .background(layer.isEnabled ? Color.primary.opacity(0.03) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
