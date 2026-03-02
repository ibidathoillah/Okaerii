// Okaerii/Logic/SceneManager.swift
import Foundation
import Combine
import SwiftUI

final class SceneManager: ObservableObject {

    // MARK: - Published State
    @Published var availableScenes: [AmbientScene] = AmbientScene.defaults
    @Published var activeScene: AmbientScene?
    @Published var playbackState: PlaybackState = .idle

    // MARK: - Engine
    let audioEngine: AudioEngine

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    init(audioEngine: AudioEngine = AudioEngine()) {
        self.audioEngine = audioEngine
        bindEngines()
    }

    private func bindEngines() {
        audioEngine.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                if isPlaying {
                    self?.playbackState = .playing
                } else if self?.activeScene == nil {
                    self?.playbackState = .idle
                } else {
                    self?.playbackState = .paused
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Scene Control
    func selectScene(_ scene: AmbientScene) {
        if let current = activeScene, current.id == scene.id {
            togglePlayback()
            return
        }

        if activeScene != nil {
            transitionToScene(scene)
        } else {
            playScene(scene)
        }
    }

    func playScene(_ scene: AmbientScene) {
        activeScene = scene
        audioEngine.play(layers: scene.audioLayers)
    }

    func stopPlayback() {
        audioEngine.stop()
        activeScene = nil
        playbackState = .idle
    }

    func togglePlayback() {
        guard let scene = activeScene else { return }
        
        if playbackState == .playing {
            audioEngine.stop()
            playbackState = .paused
        } else {
            audioEngine.play(layers: scene.audioLayers)
            playbackState = .playing
        }
    }

    private func transitionToScene(_ scene: AmbientScene) {
        activeScene = scene
        audioEngine.transitionTo(layers: scene.audioLayers)
    }
}
