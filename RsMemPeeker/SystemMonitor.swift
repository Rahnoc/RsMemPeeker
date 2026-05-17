//
//  SystemMonitor.swift
//  RsMemPeeker
//
//  Created by Rahnoc on 2025/12/19.
//

import Foundation



// 針對硬碟空間
@Observable
class SystemMonitor {
    private var timer: Timer?
    var freeDiskSpace: String = ""
    
    var isRefreshing: Bool = false
    
    
    // -----------
    
    init() {
        updateData()
        
        if Thread.isMainThread {
            start()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
        }
    }
    
    
    // -----------
    
    // 循環啟動用
    func start() {
        // 硬碟空間變化較慢，每 30~60 秒更新一次即可
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateData()
        }
        timer?.tolerance = 6.0
    }
    
    func updateData() {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        let space = getFreeDiskSpace()
        self.freeDiskSpace = formatBytes(space)
        
        
        // 限制使用者手動更新後，必須等待 1.5 秒冷卻時間，才能再次點擊
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isRefreshing = false
        }
    }
    
    
    // -----------
    
    private func getFreeDiskSpace() -> Int64 {
        let url = URL(fileURLWithPath: "/")
        do {
            // 取得重要用途的可用空間，會比單純的 free space 更準確
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage ?? 0
        } catch {
            print("讀取硬碟空間失敗: \(error)")
            return 0
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB] // 只顯示 GB 或 TB
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
