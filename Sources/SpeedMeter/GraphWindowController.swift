import Cocoa
import SwiftUI

class GraphWindowController: NSWindowController {
    private var dataStore: SpeedDataStore
    
    init(dataStore: SpeedDataStore) {
        self.dataStore = dataStore
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 550),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = "SpeedMeter - Hız Grafiği"
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 500, height: 400)
        
        // SwiftUI view'ı NSHostingView ile wrap et
        let contentView = NSHostingView(rootView: SpeedGraphView(dataStore: dataStore))
        window.contentView = contentView
        
        // Modern görünüm için
        window.titlebarAppearsTransparent = false
        window.backgroundColor = NSColor.windowBackgroundColor
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
