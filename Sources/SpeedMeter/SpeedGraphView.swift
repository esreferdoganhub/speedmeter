import SwiftUI
import Foundation

struct SpeedGraphView: View {
    @ObservedObject var dataStore: SpeedDataStore
    @State private var selectedTimeRange: TimeRange = .oneMinute
    
    enum TimeRange: String, CaseIterable {
        case thirtySeconds = "30 sn"
        case oneMinute = "1 dk"
        case fiveMinutes = "5 dk"
        case tenMinutes = "10 dk"
        
        var seconds: TimeInterval {
            switch self {
            case .thirtySeconds: return 30
            case .oneMinute: return 60
            case .fiveMinutes: return 300
            case .tenMinutes: return 600
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Başlık ve zaman aralığı seçici
            HStack {
                Text("İnternet Hız Grafiği")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Zaman Aralığı", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Anlık hız göstergesi
            HStack(spacing: 40) {
                VStack {
                    HStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.blue)
                        Text("İndirme")
                            .font(.headline)
                    }
                    Text(formatSpeed(dataStore.currentDownloadSpeed))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack {
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.green)
                        Text("Yükleme")
                            .font(.headline)
                    }
                    Text(formatSpeed(dataStore.currentUploadSpeed))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Grafik
            if !dataStore.speedHistory.isEmpty {
                SpeedChartView(
                    data: filteredData,
                    timeRange: selectedTimeRange
                )
                .frame(height: 300)
            } else {
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Veri toplanıyor...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(height: 300)
            }
            
            // İstatistikler
            HStack(spacing: 20) {
                StatCard(
                    title: "Maks İndirme",
                    value: formatSpeed(maxDownloadSpeed),
                    color: .blue
                )
                
                StatCard(
                    title: "Maks Yükleme", 
                    value: formatSpeed(maxUploadSpeed),
                    color: .green
                )
                
                StatCard(
                    title: "Ort İndirme",
                    value: formatSpeed(avgDownloadSpeed),
                    color: .blue.opacity(0.7)
                )
                
                StatCard(
                    title: "Ort Yükleme",
                    value: formatSpeed(avgUploadSpeed),
                    color: .green.opacity(0.7)
                )
            }
        }
        .padding(20)
        .frame(width: 600, height: 500)
    }
    
    private var filteredData: [SpeedDataPoint] {
        let cutoffTime = Date().timeIntervalSince1970 - selectedTimeRange.seconds
        return dataStore.speedHistory.filter { $0.timestamp >= cutoffTime }
    }
    
    private var maxDownloadSpeed: Double {
        filteredData.map { $0.downloadSpeed }.max() ?? 0
    }
    
    private var maxUploadSpeed: Double {
        filteredData.map { $0.uploadSpeed }.max() ?? 0
    }
    
    private var avgDownloadSpeed: Double {
        let speeds = filteredData.map { $0.downloadSpeed }
        return speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
    }
    
    private var avgUploadSpeed: Double {
        let speeds = filteredData.map { $0.uploadSpeed }
        return speeds.isEmpty ? 0 : speeds.reduce(0, +) / Double(speeds.count)
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let mbps = bytesPerSecond / 1_000_000
        if mbps >= 1.0 {
            return String(format: "%.1f MB/s", mbps)
        } else {
            let kbps = bytesPerSecond / 1_000
            return String(format: "%.0f KB/s", kbps)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SpeedChartView: View {
    let data: [SpeedDataPoint]
    let timeRange: SpeedGraphView.TimeRange
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arka plan grid
                BackgroundGrid()
                
                // Download hız çizgisi
                if !data.isEmpty {
                    SpeedLine(
                        data: data,
                        speedKeyPath: \.downloadSpeed,
                        color: .blue,
                        geometry: geometry,
                        timeRange: timeRange.seconds
                    )
                    
                    // Upload hız çizgisi
                    SpeedLine(
                        data: data,
                        speedKeyPath: \.uploadSpeed,
                        color: .green,
                        geometry: geometry,
                        timeRange: timeRange.seconds
                    )
                }
                
                // Y-axis labels
                YAxisLabels(data: data, geometry: geometry)
                
                // X-axis labels
                XAxisLabels(timeRange: timeRange, geometry: geometry)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SpeedLine: View {
    let data: [SpeedDataPoint]
    let speedKeyPath: KeyPath<SpeedDataPoint, Double>
    let color: Color
    let geometry: GeometryProxy
    let timeRange: TimeInterval
    
    var body: some View {
        let maxSpeed = data.map { $0[keyPath: speedKeyPath] }.max() ?? 1
        let minTime = Date().timeIntervalSince1970 - timeRange
        let maxTime = Date().timeIntervalSince1970
        
        Path { path in
            for (index, point) in data.enumerated() {
                let x = CGFloat((point.timestamp - minTime) / (maxTime - minTime)) * geometry.size.width
                let y = geometry.size.height - (CGFloat(point[keyPath: speedKeyPath] / maxSpeed) * geometry.size.height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        
        // Nokta işaretleri
        ForEach(Array(data.enumerated()), id: \.offset) { index, point in
            let x = CGFloat((point.timestamp - minTime) / (maxTime - minTime)) * geometry.size.width
            let y = geometry.size.height - (CGFloat(point[keyPath: speedKeyPath] / maxSpeed) * geometry.size.height)
            
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
                .position(x: x, y: y)
        }
    }
}

struct BackgroundGrid: View {
    var body: some View {
        Canvas { context, size in
            let horizontalLines = 5
            let verticalLines = 6
            
            context.stroke(
                Path { path in
                    // Yatay çizgiler
                    for i in 0...horizontalLines {
                        let y = CGFloat(i) * size.height / CGFloat(horizontalLines)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    
                    // Dikey çizgiler
                    for i in 0...verticalLines {
                        let x = CGFloat(i) * size.width / CGFloat(verticalLines)
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                },
                with: .color(.gray.opacity(0.2)),
                style: StrokeStyle(lineWidth: 0.5)
            )
        }
    }
}

struct YAxisLabels: View {
    let data: [SpeedDataPoint]
    let geometry: GeometryProxy
    
    var body: some View {
        let maxSpeed = max(
            data.map { $0.downloadSpeed }.max() ?? 1,
            data.map { $0.uploadSpeed }.max() ?? 1
        )
        
        VStack {
            ForEach(0..<6) { i in
                HStack {
                    Text(formatSpeed(maxSpeed * Double(5-i) / 5))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                if i < 5 { Spacer() }
            }
        }
        .frame(width: 60)
        .position(x: -20, y: geometry.size.height / 2)
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let mbps = bytesPerSecond / 1_000_000
        if mbps >= 1.0 {
            return String(format: "%.1f", mbps)
        } else {
            let kbps = bytesPerSecond / 1_000
            return String(format: "%.0f", kbps)
        }
    }
}

struct XAxisLabels: View {
    let timeRange: SpeedGraphView.TimeRange
    let geometry: GeometryProxy
    
    var body: some View {
        HStack {
            ForEach(0..<7) { i in
                VStack {
                    Spacer()
                    Text(timeLabel(for: i))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                if i < 6 { Spacer() }
            }
        }
        .position(x: geometry.size.width / 2, y: geometry.size.height + 15)
    }
    
    private func timeLabel(for index: Int) -> String {
        let secondsAgo = timeRange.seconds * Double(6-index) / 6
        let date = Date(timeIntervalSinceNow: -secondsAgo)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
