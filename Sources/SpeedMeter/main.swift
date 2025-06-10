import Cocoa
import Foundation
import SwiftUI

class SpeedMeterApp: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var speedMonitor: NetworkSpeedMonitor!
    private var settingsWindowController: SettingsWindowController?
    private var graphWindowController: GraphWindowController?
    private var settings: AppSettings = .default
    private let speedDataStore = SpeedDataStore()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ayarları yükle
        loadSettings()
        
        // Menü çubuğu öğesi oluştur
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // İkon yükle veya text fallback kullan
        if let iconPath = Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
           let icon = NSImage(contentsOfFile: iconPath) {
            icon.size = NSSize(width: 16, height: 16)
            icon.isTemplate = true // Dark mode uyumluluğu için
            statusItem.button?.image = icon
            statusItem.button?.imagePosition = .imageLeft
        } else {
            // Fallback text
            statusItem.button?.title = "⚡"
            statusItem.button?.font = NSFont.systemFont(ofSize: 14)
        }
        
        // Sol tık için action ekle
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.target = self
        
        // Sağ tık için menü ekle
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Menü oluştur (başlangıçta atama yok - sadece sağ tık için)
        
        // Hız monitörünü başlat
        speedMonitor = NetworkSpeedMonitor(updateInterval: settings.updateInterval, callback: { [weak self] downloadSpeed, uploadSpeed in
            DispatchQueue.main.async {
                self?.updateSpeedDisplay(download: downloadSpeed, upload: uploadSpeed)
                // Grafik verilerini güncelle
                self?.speedDataStore.addSpeedData(download: downloadSpeed, upload: uploadSpeed)
            }
        })
        speedMonitor.startMonitoring()
        
        // Uygulamayı dock'tan gizle
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Grafik göster
        let graphItem = NSMenuItem(title: "Hız Grafiğini Göster", action: #selector(showGraph), keyEquivalent: "g")
        graphItem.target = self
        menu.addItem(graphItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Ayarlar menüsü
        let settingsItem = NSMenuItem(title: "Ayarlar", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Çıkış
        let quitItem = NSMenuItem(title: "Çıkış", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(speedMeterApp: self)
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showGraph() {
        if graphWindowController == nil {
            graphWindowController = GraphWindowController(dataStore: speedDataStore)
        }
        graphWindowController?.showWindow(nil)
    }
    
    @objc private func statusItemClicked() {
        // Hangi tık tipini kontrol et
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            // Sağ tık - menüyü geçici olarak ata ve göster
            let tempMenu = createMenu()
            statusItem.menu = tempMenu
            statusItem.button?.performClick(nil)
            // Menüyü temizle ki sol tık çalışabilsin
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.statusItem.menu = nil
            }
        } else {
            // Sol tık - grafik penceresini aç
            showGraph()
        }
    }
    
    private func updateSpeedDisplay(download: Double, upload: Double) {
        let downloadStr = formatSpeed(download)
        let uploadStr = formatSpeed(upload)
        
        // İkon varsa sadece hızları göster, yoksa ok sembolleri ile
        if statusItem.button?.image != nil {
            statusItem.button?.title = " ↓\(downloadStr) ↑\(uploadStr)"
        } else {
            statusItem.button?.title = "↓ \(downloadStr) ↑ \(uploadStr)"
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        switch settings.displayUnit {
        case .automatic:
            let mbps = bytesPerSecond / 1_000_000
            if mbps >= 1.0 {
                return String(format: "%.1f%@", mbps, settings.showUnits ? " MB/s" : "")
            } else {
                let kbps = bytesPerSecond / 1_000
                return String(format: "%.0f%@", kbps, settings.showUnits ? " KB/s" : "")
            }
        case .megabytes:
            let mbps = bytesPerSecond / 1_000_000
            return String(format: "%.1f%@", mbps, settings.showUnits ? " MB/s" : "")
        case .kilobytes:
            let kbps = bytesPerSecond / 1_000
            return String(format: "%.0f%@", kbps, settings.showUnits ? " KB/s" : "")
        case .megabits:
            let mbps = bytesPerSecond * 8 / 1_000_000
            return String(format: "%.1f%@", mbps, settings.showUnits ? " Mbps" : "")
        case .kilobits:
            let kbps = bytesPerSecond * 8 / 1_000
            return String(format: "%.0f%@", kbps, settings.showUnits ? " Kbps" : "")
        }
    }
    
    // MARK: - Settings Management
    
    func getSettings() -> AppSettings {
        return settings
    }
    
    func saveSettings(_ newSettings: AppSettings) {
        settings = newSettings
        
        // Güncelleme aralığını değiştir
        speedMonitor.setUpdateInterval(settings.updateInterval)
        
        // UserDefaults'a kaydet
        let defaults = UserDefaults.standard
        defaults.set(settings.displayUnit.rawValue, forKey: "displayUnit")
        defaults.set(settings.updateInterval, forKey: "updateInterval")
        defaults.set(settings.showUnits, forKey: "showUnits")
        defaults.set(settings.autoStart, forKey: "autoStart")
    }
    
    func loadSettings() {
        let defaults = UserDefaults.standard
        
        settings = AppSettings(
            displayUnit: DisplayUnit(rawValue: defaults.integer(forKey: "displayUnit")) ?? .automatic,
            updateInterval: defaults.double(forKey: "updateInterval") == 0 ? 1.0 : defaults.double(forKey: "updateInterval"),
            showUnits: defaults.object(forKey: "showUnits") == nil ? true : defaults.bool(forKey: "showUnits"),
            autoStart: defaults.bool(forKey: "autoStart")
        )
    }
    
    func resetToDefaults() {
        settings = .default
        speedMonitor.setUpdateInterval(settings.updateInterval)
        
        // UserDefaults'ı temizle
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "displayUnit")
        defaults.removeObject(forKey: "updateInterval")
        defaults.removeObject(forKey: "showUnits")
        defaults.removeObject(forKey: "autoStart")
    }
    
    func setDisplayUnit(_ unit: DisplayUnit) {
        settings.displayUnit = unit
        let defaults = UserDefaults.standard
        defaults.set(unit.rawValue, forKey: "displayUnit")
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        settings.updateInterval = interval
        speedMonitor.setUpdateInterval(interval)
        let defaults = UserDefaults.standard
        defaults.set(interval, forKey: "updateInterval")
    }
    
    func setShowUnits(_ show: Bool) {
        settings.showUnits = show
        let defaults = UserDefaults.standard
        defaults.set(show, forKey: "showUnits")
    }
}

// Uygulamayı başlat
let app = NSApplication.shared
let delegate = SpeedMeterApp()
app.delegate = delegate
app.run()
