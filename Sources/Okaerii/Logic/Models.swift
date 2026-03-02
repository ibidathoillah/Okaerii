// Okaerii/Logic/Models.swift
import Foundation
import SwiftUI

// MARK: - Scene Mood
enum SceneMood: String, Codable, CaseIterable, Identifiable {
    case deepFocus = "Deep Focus"
    case deepWork = "Deep Work"
    case rainStudy = "Rain Study"
    case sunsetCalm = "Sunset Calm"
    case nightCoding = "Night Coding"
    case forestSilence = "Forest Silence"
    case oceanCalm = "Ocean Calm"
    case cafeVibes = "Café Vibes"
    case alpineDawn = "Alpine Dawn"
    case cosmicDrift = "Cosmic Drift"
    case zenGarden = "Zen Garden"
    case spaceAmbient = "Space Ambient"
    case rainyCozy = "Rainy Cozy"
    case desertNight = "Desert Night"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .deepFocus: return "brain.head.profile"
        case .deepWork: return "eyeglasses"
        case .rainStudy: return "cloud.rain"
        case .sunsetCalm: return "sunset"
        case .nightCoding: return "moon.stars"
        case .forestSilence: return "leaf"
        case .oceanCalm: return "water.waves"
        case .cafeVibes: return "cup.and.saucer.fill"
        case .alpineDawn: return "mountain.2"
        case .cosmicDrift: return "sparkles"
        case .zenGarden: return "leaf.circle"
        case .spaceAmbient: return "globe"
        case .rainyCozy: return "cloud.rain.fill"
        case .desertNight: return "moon.stars.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .deepFocus: return .blue
        case .deepWork: return .indigo
        case .rainStudy: return .cyan
        case .sunsetCalm: return .orange
        case .nightCoding: return .indigo
        case .forestSilence: return .green
        case .oceanCalm: return .teal
        case .cafeVibes: return .brown
        case .alpineDawn: return .mint
        case .cosmicDrift: return .purple
        case .zenGarden: return .green
        case .spaceAmbient: return .blue
        case .rainyCozy: return .gray
        case .desertNight: return .yellow
        }
    }
}

// MARK: - Audio Layer
struct AudioLayer: Codable, Identifiable, Hashable {
    let id: UUID
    var type: AudioLayerType
    var volume: Float
    var isEnabled: Bool
    var panPosition: Float

    init(
        id: UUID = UUID(),
        type: AudioLayerType,
        volume: Float = 0.5,
        isEnabled: Bool = true,
        panPosition: Float = 0.0
    ) {
        self.id = id
        self.type = type
        self.volume = volume
        self.isEnabled = isEnabled
        self.panPosition = panPosition
    }
}

enum AudioLayerType: String, Codable, CaseIterable, Identifiable {
    case rain
    case wind
    case fire
    case cityNoise = "city_noise"
    case thunder
    case birds
    case waves
    case whiteNoise = "white_noise"
    case cafe
    case keyboard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rain: return "Rain"
        case .wind: return "Wind"
        case .fire: return "Fireplace"
        case .cityNoise: return "City"
        case .thunder: return "Thunder"
        case .birds: return "Birds"
        case .waves: return "Ocean Waves"
        case .whiteNoise: return "White Noise"
        case .cafe: return "Cafe"
        case .keyboard: return "Keyboard"
        }
    }

    var icon: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .wind: return "wind"
        case .fire: return "flame.fill"
        case .cityNoise: return "building.2.fill"
        case .thunder: return "cloud.bolt.fill"
        case .birds: return "bird.fill"
        case .waves: return "water.waves"
        case .whiteNoise: return "waveform"
        case .cafe: return "cup.and.saucer.fill"
        case .keyboard: return "keyboard"
        }
    }
}

// MARK: - Ambient Scene
struct AmbientScene: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var mood: SceneMood
    var audioLayers: [AudioLayer]
    var isPremium: Bool

    init(
        id: UUID = UUID(),
        name: String,
        mood: SceneMood,
        audioLayers: [AudioLayer],
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.mood = mood
        self.audioLayers = audioLayers
        self.isPremium = isPremium
    }
}

extension AmbientScene {
    static let defaults: [AmbientScene] = [
        AmbientScene(
            name: "Birds",
            mood: .forestSilence,
            audioLayers: [
                AudioLayer(type: .birds, volume: 0.8),
            ]
        ),
        AmbientScene(
            name: "Silent Library",
            mood: .deepFocus,
            audioLayers: [
                AudioLayer(type: .whiteNoise, volume: 0.2),
                AudioLayer(type: .rain, volume: 0.1)
            ]
        ),
        AmbientScene(
            name: "Midnight Rain",
            mood: .rainStudy,
            audioLayers: [
                AudioLayer(type: .rain, volume: 0.7),
                AudioLayer(type: .thunder, volume: 0.2),
                AudioLayer(type: .wind, volume: 0.3)
            ]
        ),
        AmbientScene(
            name: "Deep Work",
            mood: .deepWork,
            audioLayers: [
                AudioLayer(type: .whiteNoise, volume: 0.4),
                AudioLayer(type: .keyboard, volume: 0.15)
            ]
        ),
        AmbientScene(
            name: "Golden Hour",
            mood: .sunsetCalm,
            audioLayers: [
                AudioLayer(type: .birds, volume: 0.4),
                AudioLayer(type: .wind, volume: 0.3),
                AudioLayer(type: .waves, volume: 0.2)
            ]
        ),
        AmbientScene(
            name: "Terminal Night",
            mood: .nightCoding,
            audioLayers: [
                AudioLayer(type: .rain, volume: 0.3),
                AudioLayer(type: .cafe, volume: 0.2),
                AudioLayer(type: .keyboard, volume: 0.25)
            ],
            isPremium: true
        ),
        AmbientScene(
            name: "Mountain Camp",
            mood: .alpineDawn,
            audioLayers: [
                AudioLayer(type: .fire, volume: 0.5),
                AudioLayer(type: .wind, volume: 0.2),
                AudioLayer(type: .birds, volume: 0.1)
            ]
        ),
        AmbientScene(
            name: "Urban Loft",
            mood: .cafeVibes,
            audioLayers: [
                AudioLayer(type: .cityNoise, volume: 0.3),
                AudioLayer(type: .rain, volume: 0.2),
                AudioLayer(type: .cafe, volume: 0.1)
            ]
        ),
        AmbientScene(
            name: "Stormy Coast",
            mood: .oceanCalm,
            audioLayers: [
                AudioLayer(type: .waves, volume: 0.6),
                AudioLayer(type: .thunder, volume: 0.3),
                AudioLayer(type: .wind, volume: 0.4)
            ]
        ),
    ]
}

enum PlaybackState {
    case idle
    case loading
    case playing
    case paused
    case error
}
