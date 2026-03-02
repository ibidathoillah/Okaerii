// Okaerii/UI/MenuBarController.swift
import AppKit
import SwiftUI

final class MenuBarController: NSObject, ObservableObject {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?

    private let sceneManager: SceneManager

    init(sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle", accessibilityDescription: "Okaerii")
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.animates = true

        let view = MenuBarPopoverView()
            .environmentObject(sceneManager)

        popover.contentViewController = NSHostingController(rootView: view)
        self.popover = popover

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.popover?.performClose(nil)
        }
    }

    @objc func togglePopover() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func updateIcon(isPlaying: Bool) {
        let name = isPlaying ? "waveform.circle.fill" : "waveform.circle"
        statusItem?.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: "Okaerii")
    }

    deinit {
        if let monitor = eventMonitor { NSEvent.removeMonitor(monitor) }
    }
}

// MARK: - Popover View

struct MenuBarPopoverView: View {
    @EnvironmentObject var sceneManager: SceneManager
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 12) {
            header
            sceneList
            bottomBar
        }
        .padding(12)
        .frame(width: 300, height: 400)
        .background(Color.okaerizenBackground)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(LinearGradient(colors: [Color.okaerizenPrimary, Color.okaerizenAccent], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Okaerii")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if sceneManager.playbackState == .playing {
                Circle()
                    .fill(Color.okaerizenAccent)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 4)
    }

    private var sceneList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("SCENES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.0)

                Spacer()

                let filtered = sceneManager.availableScenes.filter {
                    searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                }

                Text("\(filtered.count)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Capsule())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            ScrollView {
                LazyVStack(spacing: 4) {
                    let filtered = sceneManager.availableScenes.filter {
                        searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                    }
                    ForEach(filtered) { scene in
                        sceneRow(scene)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sceneRow(_ scene: AmbientScene) -> some View {
        let isActive = scene.id == sceneManager.activeScene?.id

        return Button(action: { sceneManager.selectScene(scene) }) {
            HStack(spacing: 8) {
                Image(systemName: scene.mood.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isActive ? Color.okaerizenPrimary : .secondary)
                    .frame(width: 24, height: 24)
                    .background(scene.mood.accentColor.opacity(isActive ? 0.2 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 1) {
                    Text(scene.name)
                        .font(.system(size: 12, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? .primary : .secondary)
                        .lineLimit(1)
                    
                    Text(scene.mood.rawValue)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.okaerizenPrimary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isActive ? Color.okaerizenPrimary.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            // Volume Slider
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Slider(
                    value: Binding(
                        get: { Double(sceneManager.audioEngine.masterVolume) },
                        set: { sceneManager.audioEngine.setMasterVolume(Float($0)) }
                    ),
                    in: 0...1
                )
                .controlSize(.mini)
                .tint(Color.okaerizenPrimary)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                    Text("Quit Okaerii")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
