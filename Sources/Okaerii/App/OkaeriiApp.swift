// Okaerii/App/OkaeriiApp.swift
import SwiftUI
import AppKit

@main
struct OkaeriiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    let sceneManager = SceneManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // This is a menu bar only app
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController(sceneManager: sceneManager)
        menuBarController?.setup()
    }
}
