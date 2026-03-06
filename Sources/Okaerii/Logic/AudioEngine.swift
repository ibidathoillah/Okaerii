// Okaerii/Logic/AudioEngine.swift
import Foundation
import AVFoundation
import Combine

final class AudioEngine: ObservableObject {

    // MARK: - Published State
    @Published var isPlaying: Bool = false
    @Published var activeLayers: [AudioLayerType: Float] = [:]
    @Published var masterVolume: Float = 1.0

    // MARK: - Engine
    private let engine = AVAudioEngine()
    private let crossfadeDuration: TimeInterval = 2.0

    // MARK: - Layer Nodes
    private var playerNodes: [AudioLayerType: AVAudioPlayerNode] = [:]
    private var audioBuffers: [AudioLayerType: AVAudioPCMBuffer] = [:]
    private var layerVolumes: [AudioLayerType: Float] = [:]
    private var fadeTimers: [AudioLayerType: Timer] = [:]

    init() {
        configureEngine()
        setupNotifications()
        preloadAllLayers()
    }

    private func preloadAllLayers() {
        // Preload buffers in background to avoid blocking UI at startup or during first playback
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for type in AudioLayerType.allCases {
                self?.preloadBuffer(for: type)
            }
        }
    }

    private func preloadBuffer(for type: AudioLayerType) {
        let dummyLayer = AudioLayer(type: type)
        guard let url = audioFileURL(for: dummyLayer) else { return }
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let buffer = try loadBuffer(from: audioFile)
            
            DispatchQueue.main.async { [weak self] in
                self?.audioBuffers[type] = buffer
            }
        } catch {
            print("[AudioEngine] Failed to preload \(type.rawValue): \(error)")
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEngineConfigurationChange),
            name: .AVAudioEngineConfigurationChange,
            object: engine
        )
    }

    @objc private func handleEngineConfigurationChange() {
        // When configuration changes (e.g., headphones plugged in/out), 
        // we might need to restart the engine if it was playing
        guard isPlaying else { return }
        
        // Re-start the engine and re-setup nodes if necessary
        // AVAudioEngine documentation says we should restart it
        DispatchQueue.main.async { [weak self] in
            self?.startEngine()
        }
    }

    private func configureEngine() {
        engine.mainMixerNode.outputVolume = masterVolume
    }

    // MARK: - Playback Control
    func play(layers: [AudioLayer]) {
        if !engine.isRunning {
            startEngine()
        }

        for layer in layers where layer.isEnabled {
            loadAndPlay(layer: layer)
        }

        isPlaying = true
    }

    func stop() {
        for (type, node) in playerNodes {
            fadeOut(type: type) { [weak self] in
                node.stop()
                self?.removeLayerNode(type)
            }
        }
        isPlaying = false
        activeLayers.removeAll()

        DispatchQueue.main.asyncAfter(deadline: .now() + crossfadeDuration + 0.1) { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.engine.stop()
        }
    }

    func setLayerVolume(_ type: AudioLayerType, volume: Float) {
        layerVolumes[type] = volume
        playerNodes[type]?.volume = volume
        activeLayers[type] = volume
    }

    func setMasterVolume(_ volume: Float) {
        masterVolume = volume
        engine.mainMixerNode.outputVolume = volume
    }

    func transitionTo(layers: [AudioLayer], duration: TimeInterval = 2.0) {
        let newTypes = Set(layers.filter { $0.isEnabled }.map { $0.type })
        let currentTypes = Set(playerNodes.keys)

        if !engine.isRunning {
            startEngine()
        }

        let toRemove = currentTypes.subtracting(newTypes)
        for type in toRemove {
            fadeOut(type: type) { [weak self] in
                self?.playerNodes[type]?.stop()
                self?.removeLayerNode(type)
                self?.activeLayers.removeValue(forKey: type)
            }
        }

        for layer in layers where layer.isEnabled {
            if playerNodes[layer.type] != nil {
                animateVolume(type: layer.type, to: layer.volume, duration: duration)
            } else {
                loadAndPlay(layer: layer, fadeIn: true)
            }
        }
    }

    // MARK: - Private: Engine Lifecycle
    private func startEngine() {
        guard !engine.isRunning else { return }
        do {
            engine.prepare()
            try engine.start()
        } catch {
            print("[AudioEngine] Failed to start engine: \(error)")
        }
    }

    private func loadAndPlay(layer: AudioLayer, fadeIn: Bool = true) {
        // Use cached buffer if available, otherwise load in background
        if let cachedBuffer = audioBuffers[layer.type] {
            setupAndStartNode(layer: layer, buffer: cachedBuffer, fadeIn: fadeIn)
        } else {
            // Load asynchronously
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                guard let url = self.audioFileURL(for: layer) else {
                    print("[AudioEngine] No audio file found for \(layer.type.rawValue)")
                    return
                }

                do {
                    let audioFile = try AVAudioFile(forReading: url)
                    let buffer = try self.loadBuffer(from: audioFile)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.audioBuffers[layer.type] = buffer
                        self.setupAndStartNode(layer: layer, buffer: buffer, fadeIn: fadeIn)
                    }
                } catch {
                    print("[AudioEngine] Error loading audio for \(layer.type.rawValue): \(error)")
                }
            }
        }
    }

    private func setupAndStartNode(layer: AudioLayer, buffer: AVAudioPCMBuffer, fadeIn: Bool) {
        do {
            if playerNodes[layer.type] != nil {
                removeLayerNode(layer.type)
            }

            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)

            if !engine.isRunning {
                startEngine()
            }

            // Ensure we are connected with the correct format
            engine.connect(playerNode, to: engine.mainMixerNode, format: buffer.format)

            if fadeIn {
                playerNode.volume = 0
            } else {
                playerNode.volume = layer.volume
            }

            playerNodes[layer.type] = playerNode
            layerVolumes[layer.type] = layer.volume
            activeLayers[layer.type] = layer.volume

            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            
            // Only play if the engine is running
            if engine.isRunning {
                playerNode.play()
            } else {
                startEngine()
                if engine.isRunning {
                    playerNode.play()
                } else {
                    print("[AudioEngine] Error: Could not play layer \(layer.type.rawValue) because engine failed to start.")
                }
            }

            if fadeIn {
                animateVolume(type: layer.type, to: layer.volume, duration: crossfadeDuration)
            }
        }
    }

    private func loadBuffer(from audioFile: AVAudioFile) throws -> AVAudioPCMBuffer {
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioEngine", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PCM buffer"])
        }

        audioFile.framePosition = 0
        try audioFile.read(into: buffer)
        return buffer
    }

    private func removeLayerNode(_ type: AudioLayerType) {
        fadeTimers[type]?.invalidate()
        fadeTimers.removeValue(forKey: type)

        if let node = playerNodes[type] {
            node.stop()
            engine.detach(node)
        }

        playerNodes.removeValue(forKey: type)
        layerVolumes.removeValue(forKey: type)
    }

    private static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }

    private func audioFileURL(for layer: AudioLayer) -> URL? {
        let name = layer.type.rawValue
        let bundle = Self.resourceBundle
        
        // Try to find in bundle
        for ext in ["mp3", "m4a", "wav"] {
            // First try root of bundle (where .process() usually puts them)
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
            // Then try Audio subdirectory in bundle
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Audio") {
                return url
            }
            // Also try with uppercase extensions just in case
            if let url = bundle.url(forResource: name, withExtension: ext.uppercased()) {
                return url
            }
        }
        
        // Try to find in a relative path from the executable (for local dev when not in bundle)
        let possiblePaths = [
            "Sources/Okaerii/Audio/\(name).mp3",
            "../Sources/Okaerii/Audio/\(name).mp3",
            "../Resources/Audio/\(name).mp3",
            "Resources/Audio/\(name).mp3",
            "Audio/\(name).mp3"
        ]
        
        for path in possiblePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return nil
    }

    private func fadeOut(type: AudioLayerType, completion: @escaping () -> Void) {
        animateVolume(type: type, to: 0, duration: crossfadeDuration, completion: completion)
    }

    private func animateVolume(type: AudioLayerType, to targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        fadeTimers[type]?.invalidate()

        guard let node = playerNodes[type] else {
            completion?()
            return
        }

        let steps = 60
        let interval = duration / Double(steps)
        let startVolume = node.volume
        let delta = (targetVolume - startVolume) / Float(steps)
        var currentStep = 0

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            currentStep += 1
            if currentStep >= steps {
                node.volume = targetVolume
                timer.invalidate()
                self?.fadeTimers.removeValue(forKey: type)
                self?.layerVolumes[type] = targetVolume
                completion?()
            } else {
                node.volume = startVolume + delta * Float(currentStep)
            }
        }

        fadeTimers[type] = timer
    }

    deinit {
        fadeTimers.values.forEach { $0.invalidate() }
        engine.stop()
    }
}
