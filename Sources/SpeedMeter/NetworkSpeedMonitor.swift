import Foundation
import SystemConfiguration

class NetworkSpeedMonitor {
    private var timer: Timer?
    private var previousTimestamp: TimeInterval = 0
    private var previousBytesReceived: UInt64 = 0
    private var previousBytesSent: UInt64 = 0
    private var updateInterval: TimeInterval
    
    // Smoothing için son birkaç ölçümü sakla
    private var downloadSpeeds: [Double] = []
    private var uploadSpeeds: [Double] = []
    private let maxSamples = 3
    
    typealias SpeedUpdateCallback = (Double, Double) -> Void
    private let callback: SpeedUpdateCallback
    
    init(updateInterval: TimeInterval = 1.0, callback: @escaping SpeedUpdateCallback) {
        self.updateInterval = updateInterval
        self.callback = callback
    }
    
    func startMonitoring() {
        // İlk ölçümü al
        updateNetworkStats()
        
        // Timer'ı başlat
        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateNetworkStats()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        updateInterval = interval
        if timer != nil {
            stopMonitoring()
            // Değişiklik sonrası ilk ölçümü sıfırla
            previousTimestamp = 0
            previousBytesReceived = 0
            previousBytesSent = 0
            downloadSpeeds.removeAll()
            uploadSpeeds.removeAll()
            startMonitoring()
        }
    }
    
    private func updateNetworkStats() {
        guard let stats = getNetworkStatsFromNetstat() else { 
            print("Network stats alınamadı!")
            return 
        }
        
        let currentTimestamp = Date().timeIntervalSince1970
        
        if previousTimestamp > 0 {
            let timeDiff = currentTimestamp - previousTimestamp
            let receivedDiff = stats.bytesReceived > previousBytesReceived ? 
                               stats.bytesReceived - previousBytesReceived : 0
            let sentDiff = stats.bytesSent > previousBytesSent ? 
                          stats.bytesSent - previousBytesSent : 0
            
            let downloadSpeed = Double(receivedDiff) / timeDiff
            let uploadSpeed = Double(sentDiff) / timeDiff
            
            print("Anlık Hız - İndirme: \(Int(downloadSpeed/1000)) KB/s, Yükleme: \(Int(uploadSpeed/1000)) KB/s")
            
            // Smoothing uygula
            downloadSpeeds.append(downloadSpeed)
            uploadSpeeds.append(uploadSpeed)
            
            if downloadSpeeds.count > maxSamples {
                downloadSpeeds.removeFirst()
            }
            if uploadSpeeds.count > maxSamples {
                uploadSpeeds.removeFirst()
            }
            
            let avgDownload = downloadSpeeds.reduce(0, +) / Double(downloadSpeeds.count)
            let avgUpload = uploadSpeeds.reduce(0, +) / Double(uploadSpeeds.count)
            
            callback(avgDownload, avgUpload)
        }
        
        previousTimestamp = currentTimestamp
        previousBytesReceived = stats.bytesReceived
        previousBytesSent = stats.bytesSent
    }
    
    private func getNetworkStatsFromNetstat() -> (bytesReceived: UInt64, bytesSent: UInt64)? {
        let task = Process()
        task.launchPath = "/usr/sbin/netstat"
        task.arguments = ["-ib", "-I", "en0"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            
            // netstat çıktısını parse et
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("en0") && !line.contains("Name") {
                    let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if components.count >= 10 {
                        let received = UInt64(components[6]) ?? 0
                        let sent = UInt64(components[9]) ?? 0
                        print("netstat - RX: \(received), TX: \(sent)")
                        return (received, sent)
                    }
                }
            }
        } catch {
            print("netstat failed: \(error)")
        }
        
        return nil
    }
}

