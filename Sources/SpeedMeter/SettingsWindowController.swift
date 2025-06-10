import Cocoa
import Foundation

class SettingsWindowController: NSWindowController {
    private var speedMeterApp: SpeedMeterApp!
    
    // UI Elements
    private var unitPopup: NSPopUpButton!
    private var intervalSlider: NSSlider!
    private var intervalLabel: NSTextField!
    private var autoStartCheckbox: NSButton!
    private var showUnitsCheckbox: NSButton!
    
    init(speedMeterApp: SpeedMeterApp) {
        self.speedMeterApp = speedMeterApp
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
        setupUI()
        loadSettings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWindow() {
        guard let window = window else { return }
        
        window.title = "SpeedMeter Ayarları"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSView()
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Görüntüleme Modu
        let displaySection = createDisplaySection()
        stackView.addArrangedSubview(displaySection)
        
        // Güncelleme Aralığı
        let intervalSection = createIntervalSection()
        stackView.addArrangedSubview(intervalSection)
        
        // Genel Ayarlar
        let generalSection = createGeneralSection()
        stackView.addArrangedSubview(generalSection)
        
        // Butonlar
        let buttonSection = createButtonSection()
        stackView.addArrangedSubview(buttonSection)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createDisplaySection() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = NSTextField(labelWithString: "Görüntüleme Modu:")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        unitPopup = NSPopUpButton()
        unitPopup.translatesAutoresizingMaskIntoConstraints = false
        unitPopup.addItems(withTitles: [
            "Otomatik (MB/s - KB/s)",
            "Megabyte/saniye (MB/s)",
            "Kilobyte/saniye (KB/s)",
            "Megabit/saniye (Mbps)",
            "Kilobit/saniye (Kbps)"
        ])
        unitPopup.target = self
        unitPopup.action = #selector(unitChanged)
        
        showUnitsCheckbox = NSButton(checkboxWithTitle: "Birimleri göster", target: self, action: #selector(showUnitsChanged))
        showUnitsCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(unitPopup)
        container.addSubview(showUnitsCheckbox)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            unitPopup.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            unitPopup.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            unitPopup.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            showUnitsCheckbox.topAnchor.constraint(equalTo: unitPopup.bottomAnchor, constant: 8),
            showUnitsCheckbox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            showUnitsCheckbox.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createIntervalSection() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = NSTextField(labelWithString: "Güncelleme Aralığı:")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        intervalSlider = NSSlider()
        intervalSlider.translatesAutoresizingMaskIntoConstraints = false
        intervalSlider.minValue = 0.5
        intervalSlider.maxValue = 5.0
        intervalSlider.doubleValue = 1.0
        intervalSlider.numberOfTickMarks = 10
        intervalSlider.allowsTickMarkValuesOnly = false
        intervalSlider.target = self
        intervalSlider.action = #selector(intervalChanged)
        
        intervalLabel = NSTextField(labelWithString: "1.0 saniye")
        intervalLabel.translatesAutoresizingMaskIntoConstraints = false
        intervalLabel.alignment = .center
        
        container.addSubview(titleLabel)
        container.addSubview(intervalSlider)
        container.addSubview(intervalLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            intervalSlider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            intervalSlider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            intervalSlider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            intervalLabel.topAnchor.constraint(equalTo: intervalSlider.bottomAnchor, constant: 4),
            intervalLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            intervalLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createGeneralSection() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = NSTextField(labelWithString: "Genel:")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        autoStartCheckbox = NSButton(checkboxWithTitle: "Sistem başlangıcında otomatik başlat", target: self, action: #selector(autoStartChanged))
        autoStartCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(autoStartCheckbox)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            autoStartCheckbox.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            autoStartCheckbox.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            autoStartCheckbox.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func createButtonSection() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let resetButton = NSButton(title: "Varsayılana Sıfırla", target: self, action: #selector(resetToDefaults))
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        let closeButton = NSButton(title: "Kapat", target: self, action: #selector(closeWindow))
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.keyEquivalent = "\r"
        
        container.addSubview(resetButton)
        container.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            resetButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            resetButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func unitChanged() {
        speedMeterApp.setDisplayUnit(DisplayUnit(rawValue: unitPopup.indexOfSelectedItem) ?? .automatic)
        saveSettings()
    }
    
    @objc private func intervalChanged() {
        let interval = intervalSlider.doubleValue
        intervalLabel.stringValue = String(format: "%.1f saniye", interval)
        speedMeterApp.setUpdateInterval(interval)
        saveSettings()
    }
    
    @objc private func showUnitsChanged() {
        speedMeterApp.setShowUnits(showUnitsCheckbox.state == .on)
        saveSettings()
    }
    
    @objc private func autoStartChanged() {
        // Bu özellik gelecekte implementasyon edilecek
        saveSettings()
    }
    
    @objc private func resetToDefaults() {
        unitPopup.selectItem(at: 0)
        intervalSlider.doubleValue = 1.0
        intervalLabel.stringValue = "1.0 saniye"
        showUnitsCheckbox.state = .on
        autoStartCheckbox.state = .off
        
        speedMeterApp.resetToDefaults()
        saveSettings()
    }
    
    @objc private func closeWindow() {
        close()
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        let settings = speedMeterApp.getSettings()
        
        unitPopup.selectItem(at: settings.displayUnit.rawValue)
        intervalSlider.doubleValue = settings.updateInterval
        intervalLabel.stringValue = String(format: "%.1f saniye", settings.updateInterval)
        showUnitsCheckbox.state = settings.showUnits ? .on : .off
        autoStartCheckbox.state = settings.autoStart ? .on : .off
    }
    
    private func saveSettings() {
        let settings = AppSettings(
            displayUnit: DisplayUnit(rawValue: unitPopup.indexOfSelectedItem) ?? .automatic,
            updateInterval: intervalSlider.doubleValue,
            showUnits: showUnitsCheckbox.state == .on,
            autoStart: autoStartCheckbox.state == .on
        )
        speedMeterApp.saveSettings(settings)
    }
}
