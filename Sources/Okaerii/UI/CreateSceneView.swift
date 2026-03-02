import SwiftUI

struct CreateSceneView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var sceneManager: SceneManager
    
    @State private var name: String = ""
    @State private var selectedMood: SceneMood = .deepFocus
    @State private var layers: [AudioLayer] = AudioLayerType.allCases.map {
        AudioLayer(type: $0, volume: 0.5, isEnabled: false)
    }
    
    // Track original scene to restore on cancel
    @State private var originalScene: AmbientScene?
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Button(action: cancelCreation) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text("New Scene")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Name Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NAME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        TextField("Scene Name", text: $name)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Mood Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MOOD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SceneMood.allCases) { mood in
                                    Button(action: { selectedMood = mood }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: mood.icon)
                                                .font(.system(size: 16))
                                            
                                        }
                                        .frame(width: 36, height: 36)
                                        .background(selectedMood == mood ? mood.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                                        .foregroundStyle(selectedMood == mood ? mood.accentColor : .secondary)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(selectedMood == mood ? mood.accentColor : Color.clear, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(2)
                        }
                    }
                    
                    // Layers
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AUDIO LAYERS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            ForEach($layers) { $layer in
                                LayerToggleRow(
                                    layer: $layer,
                                    onToggle: updatePreview,
                                    onVolumeChange: { newVolume in
                                        sceneManager.audioEngine.setLayerVolume(layer.type, volume: newVolume)
                                    }
                                )
                            }
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(4)
            }
            
            // Save Button
            Button(action: saveScene) {
                Text("Create Scene")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(canSave ? Color.okaerizenPrimary : Color.secondary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .onAppear {
            originalScene = sceneManager.activeScene
        }
    }
    
    private var canSave: Bool {
        !name.isEmpty && layers.contains { $0.isEnabled }
    }
    
    private func updatePreview() {
        let activeLayers = layers.filter { $0.isEnabled }
        sceneManager.audioEngine.transitionTo(layers: activeLayers, duration: 0.5)
        
        // If we started playing something, make sure UI reflects playing state
        if !activeLayers.isEmpty && sceneManager.playbackState != .playing {
            sceneManager.playbackState = .playing
        }
    }
    
    private func cancelCreation() {
        if let original = originalScene {
            // Restore original scene
            sceneManager.selectScene(original)
        } else {
            // Stop whatever preview was playing
            sceneManager.stopPlayback()
        }
        withAnimation {
            isPresented = false
        }
    }
    
    private func saveScene() {
        let activeLayers = layers.filter { $0.isEnabled }
        let newScene = AmbientScene(
            name: name,
            mood: selectedMood,
            audioLayers: activeLayers
        )
        
        sceneManager.availableScenes.append(newScene)
        sceneManager.selectScene(newScene)
        withAnimation {
            isPresented = false
        }
    }
}
