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
    private var audioFiles: [AudioLayerType: AVAudioFile] = [:]
    private var layerVolumes: [AudioLayerType: Float] = [:]
    private var fadeTimers: [AudioLayerType: Timer] = [:]

    init() {
        configureEngine()
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
            try engine.start()
        } catch {
            print("[AudioEngine] Failed to start engine: \(error)")
        }
    }

    private func loadAndPlay(layer: AudioLayer, fadeIn: Bool = true) {
        guard let url = audioFileURL(for: layer) else {
            print("[AudioEngine] No audio file found for \(layer.type.rawValue)")
            return
        }

        do {
            let audioFile = try AVAudioFile(forReading: url)

            if playerNodes[layer.type] != nil {
                removeLayerNode(layer.type)
            }

            let playerNode = AVAudioPlayerNode()
            engine.attach(playerNode)

            let processingFormat = audioFile.processingFormat
            engine.connect(playerNode, to: engine.mainMixerNode, format: processingFormat)

            let buffer = try loadBuffer(from: audioFile)

            if fadeIn {
                playerNode.volume = 0
            } else {
                playerNode.volume = layer.volume
            }

            playerNodes[layer.type] = playerNode
            audioFiles[layer.type] = audioFile
            layerVolumes[layer.type] = layer.volume
            activeLayers[layer.type] = layer.volume

            if !engine.isRunning {
                startEngine()
            }

            playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            playerNode.play()

            if fadeIn {
                animateVolume(type: layer.type, to: layer.volume, duration: crossfadeDuration)
            }

        } catch {
            print("[AudioEngine] Error loading audio for \(layer.type.rawValue): \(error)")
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
            engine.detach(node)
        }

        playerNodes.removeValue(forKey: type)
        audioFiles.removeValue(forKey: type)
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
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Audio") {
                return url
            }
        }
        
        // Try to find in a relative path from the executable (for local dev)
        let possiblePaths = [
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

        let steps = 30
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
