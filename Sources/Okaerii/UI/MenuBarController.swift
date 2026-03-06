import AppKit
import SwiftUI

final class MenuBarController: NSObject, ObservableObject {

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var onboardingWindow: NSWindow?

    private let sceneManager: SceneManager
    
    // Using UserDefaults directly since we are outside SwiftUI view hierarchy
    private var hasSeenIntro: Bool {
        get { UserDefaults.standard.bool(forKey: "hasSeenIntro") }
        set { UserDefaults.standard.set(newValue, forKey: "hasSeenIntro") }
    }

    init(sceneManager: SceneManager) {
        self.sceneManager = sceneManager
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "🍵"
            button.image = nil
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 500)
        popover.behavior = .transient
        popover.animates = true

        let view = MenuBarPopoverView()
            .environmentObject(sceneManager)

        popover.contentViewController = NSHostingController(rootView: view)
        self.popover = popover

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.popover?.performClose(nil)
        }
        
        // Check for onboarding
        if !hasSeenIntro {
            showOnboardingWindow()
        }
    }
    
    private func showOnboardingWindow() {
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Welcome to Okaerii"
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        
        // Setup content
        let onboardingView = OnboardingView(isPresented: Binding(
            get: { !self.hasSeenIntro },
            set: { [weak self] isPresented in
                if !isPresented {
                    // User clicked "Get Started"
                    self?.hasSeenIntro = true
                    self?.onboardingWindow?.close()
                    self?.onboardingWindow = nil
                    
                    // Show the popover to indicate where the app lives
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.togglePopover()
                    }
                }
            }
        ))
        
        window.contentView = NSHostingView(rootView: onboardingView)
        window.makeKeyAndOrderFront(nil)
        
        // Ensure app is active to show the window
        NSApp.activate(ignoringOtherApps: true)
        
        self.onboardingWindow = window
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
        statusItem?.button?.title = "🍵"
        statusItem?.button?.image = nil
    }

    deinit {
        if let monitor = eventMonitor { NSEvent.removeMonitor(monitor) }
    }
}

// MARK: - Popover View

struct MenuBarPopoverView: View {
    @EnvironmentObject var sceneManager: SceneManager
    @State private var searchText: String = ""
    @State private var isCreatingScene: Bool = false
    @State private var isAboutPresented: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            if isCreatingScene {
                CreateSceneView(isPresented: $isCreatingScene)
            } else {
                header
                sceneList
                bottomBar
            }
        }
        .padding(12)
        .frame(width: 300, height: 500)
        .background(Color.okaerizenBackground)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("🍵")
                .font(.system(size: 16))

            Text("Okaerii")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if sceneManager.playbackState == .playing {
                Circle()
                    .fill(Color.okaerizenAccent)
                    .frame(width: 6, height: 6)
            }
            
            Button(action: { withAnimation { isCreatingScene = true } }) {
                Image(systemName: "plus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(Color.primary.opacity(0.05))
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    private var sceneList: some View {
        VStack(spacing: 8) {
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

            HStack(spacing: 8) {
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: { isAboutPresented.toggle() }) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isAboutPresented, arrowEdge: .bottom) {
                    AboutView()
                }
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 4) {
                HStack(alignment: .center, spacing: 6) {
                    Text("Okaerii")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                }
                
                Button(action: {
                    if let url = URL(string: "https://github.com/ibidathoillah") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("@ibidathoillah")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .underline(true, color: .secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            
            Text("Made with 🍵")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(width: 180)
    }
}
