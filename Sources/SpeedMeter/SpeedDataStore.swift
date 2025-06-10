import Foundation
import Combine

struct SpeedDataPoint {
    let timestamp: TimeInterval
    let downloadSpeed: Double  // bytes per second
    let uploadSpeed: Double    // bytes per second
}

class SpeedDataStore: ObservableObject {
    @Published var speedHistory: [SpeedDataPoint] = []
    @Published var currentDownloadSpeed: Double = 0
    @Published var currentUploadSpeed: Double = 0
    
    private let maxHistoryDuration: TimeInterval = 600 // 10 dakika
    private let maxDataPoints = 600 // Maximum veri noktası sayısı
    
    func addSpeedData(download: Double, upload: Double) {
        let dataPoint = SpeedDataPoint(
            timestamp: Date().timeIntervalSince1970,
            downloadSpeed: download,
            uploadSpeed: upload
        )
        
        DispatchQueue.main.async {
            // Mevcut hızları güncelle
            self.currentDownloadSpeed = download
            self.currentUploadSpeed = upload
            
            // Yeni veri noktasını ekle
            self.speedHistory.append(dataPoint)
            
            // Eski verileri temizle (10 dakikadan eski)
            let cutoffTime = Date().timeIntervalSince1970 - self.maxHistoryDuration
            self.speedHistory.removeAll { $0.timestamp < cutoffTime }
            
            // Veri noktası sayısını sınırla
            if self.speedHistory.count > self.maxDataPoints {
                let excessCount = self.speedHistory.count - self.maxDataPoints
                self.speedHistory.removeFirst(excessCount)
            }
        }
    }
    
    func clearHistory() {
        DispatchQueue.main.async {
            self.speedHistory.removeAll()
            self.currentDownloadSpeed = 0
            self.currentUploadSpeed = 0
        }
    }
    
    // İstatistik hesaplama metodları
    func getMaxSpeed(for timeRange: TimeInterval) -> (download: Double, upload: Double) {
        let cutoffTime = Date().timeIntervalSince1970 - timeRange
        let filteredData = speedHistory.filter { $0.timestamp >= cutoffTime }
        
        let maxDownload = filteredData.map { $0.downloadSpeed }.max() ?? 0
        let maxUpload = filteredData.map { $0.uploadSpeed }.max() ?? 0
        
        return (download: maxDownload, upload: maxUpload)
    }
    
    func getAverageSpeed(for timeRange: TimeInterval) -> (download: Double, upload: Double) {
        let cutoffTime = Date().timeIntervalSince1970 - timeRange
        let filteredData = speedHistory.filter { $0.timestamp >= cutoffTime }
        
        guard !filteredData.isEmpty else {
            return (download: 0, upload: 0)
        }
        
        let avgDownload = filteredData.map { $0.downloadSpeed }.reduce(0, +) / Double(filteredData.count)
        let avgUpload = filteredData.map { $0.uploadSpeed }.reduce(0, +) / Double(filteredData.count)
        
        return (download: avgDownload, upload: avgUpload)
    }
}
