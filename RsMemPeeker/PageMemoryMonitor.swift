//
//  PageMemoryMonitor.swift
//  RsMemPeeker
//
//  Created by Rahnoc on 2026/5/17.
//

import Foundation
import MachO



// 針對 page-out 計算平均數，取得 MB/s。
class PageMemoryMonitor {
    private var lastPageouts: UInt64 = 0
    private var isFirstRun = true
    private var timer: Timer?
    private let interval: TimeInterval
    private let pageSize = UInt64(vm_kernel_page_size)
    
    // 使用的 mock.
    private var mockAs: DeviceCapibilityType?
    
    // 平均 page out (記憶體寫入磁碟) 吞吐量。
    var averagePageoutsPerSecondMB: Double
    
    
    // --------------
    
    // 預設每 5 秒抓一次
    init(mockAs: DeviceCapibilityType?=nil, interval: TimeInterval=5.0) {
        averagePageoutsPerSecondMB = 0.0
        self.interval = interval
        self.mockAs = mockAs
        
        if Thread.isMainThread {
            start()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
        }
    }
    
    
    // --------------
    
    private func start() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.averagePageoutsPerSecondMB = self?.checkSystemLoad() ?? 0.0
        }
        timer?.tolerance = 0.5
    }
    
    
    @discardableResult
    private func checkSystemLoad() -> Double {
        // A. 模擬
        if let target = mockAs {
            let bound = DeviceCapibilityType.getPageOutRndBoundary(targt: target)
            return Double.random(in: 0 ... bound)
        }
        
        
        // B. 實機
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64_data_t()
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0}
        let currentPageouts = vmStats.pageouts
        
        if isFirstRun {
            lastPageouts = currentPageouts
            isFirstRun = false
            return 0
        }
        
        // 計算這 5 秒內的總分頁差額
        let diffPageouts = currentPageouts &- lastPageouts
        lastPageouts = currentPageouts
        
        // 先算出這 5 秒寫入的總 MB 數
        let totalMBInInterval = Double(diffPageouts * pageSize) / (1024 * 1024)
        
        // 除以時間間隔（5秒），算出平滑後的「每秒寫出量 (MB/s)」
        let averagePageoutsPerSecondMB = totalMBInInterval / interval
        
        
        return averagePageoutsPerSecondMB
    }
}

