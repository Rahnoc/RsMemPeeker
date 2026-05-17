//
//  MemoryMonitor.swift
//  RsMemPeeker
//
//  Created by Rahnoc on 2025/12/19.
//

import SwiftUI
import Combine



// 針對記憶體顯示
@Observable
class MemoryMonitor {
    // 記憶體壓力
    private var pressureLevel: Int32 = -1
    private var timer: Timer?
    
    // 使用的 mock.
    private var mockAs: DeviceCapibilityType?
    
    
    // 記憶體壓力等級
    var pLevel: MemPreLevel { MemPreLevel.convert(num: pressureLevel) }
    // 交換檔大小
    var swapInfo: SwapUsageInfo?
    
    // ---------------
    
    // mockAs 非 nil 時，根據 mock目標定時亂取當作資訊。
    init(mockAs: DeviceCapibilityType?=nil) {
        self.mockAs = mockAs
        
        if Thread.isMainThread {
            start()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
        }
    }
    
    // 循環用
    func start() {
        // 首次執行
        pressureLevel = getMemoryPressure()
        swapInfo = getSwapUsage()
        
        
        // 每 5 秒更新一次
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.pressureLevel = self?.getMemoryPressure() ?? -1
            self?.swapInfo = self?.getSwapUsage() ?? nil
        }
        timer?.tolerance = 0.5
    }
    
    
    // --------------
    
    // 回傳值為 1,2,4
    private func getMemoryPressure() -> Int32 {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        // 呼叫系統接口讀取記憶體壓力等級
        let result = sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0)
        return result == 0 ? level : -1 // 失敗回傳 -1
    }
    
    // --------------
    
    // 取得交換檔用量
    private func getSwapUsage() -> SwapUsageInfo? {
        
        // A. 如果為 mock 模式時：
        if let target = mockAs {
            let rndBoundary = DeviceCapibilityType.getMockSwapRndBoundary(target: target)
            let used = Double.random(in: 0 ... rndBoundary)
            
            return SwapUsageInfo(
                total: UInt64(rndBoundary * 1024 * 1024 * 1024),
                used: UInt64(used * 1024 * 1024 * 1024),         // 這裡 使用的交換檔 為本 app 看的重點。
                free: UInt64((rndBoundary - used) * 1024 * 1024 * 1024)
            )
        }
        
        
        // --------------
        // B. 不然 根據實機抓到的資料計算
        
        var mib: [Int32] = [CTL_VM, VM_SWAPUSAGE]
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        
        let result = sysctl(&mib, u_int(mib.count), &usage, &size, nil, 0)
        
        if result == 0 {
            return SwapUsageInfo(
                total: usage.xsu_total,
                used: usage.xsu_used,
                free: usage.xsu_avail
            )
        } else {
            print("無法取得 Swap 資訊")
            return nil
        }
    }
    
}


// ------------------

// 記憶體壓力等級
public enum MemPreLevel: CustomStringConvertible {
    case unknow
    case normal     // 1
    case warning    // 2
    case critical   // 4
    
    // 1,2,4 parser
    static func convert(num:Int32) -> Self {
        switch(num) {
        case 1:
            return .normal
        case 2:
            return .warning
        case 4:
            return .critical
        default:
            return .unknow
        }
    }
    
    var color: Color {
        switch(self) {
        case .normal:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        case .unknow:
            return .gray
        }
    }
    
    public var description: String {
        switch(self) {
        case .normal:
            return "正常"
        case .warning:
            return "警告"
        case .critical:
            return "嚴重"
        case .unknow:
            return "未知"
        }
    }
}


// 針對 swap 用量。
struct SwapUsageInfo {
    var total: UInt64  // 總 Swap 空間 (Bytes)
    var used: UInt64   // 已使用 Swap (Bytes)
    var free: UInt64   // 剩餘 Swap (Bytes)
    
    // 轉為人類可讀的字串格式 (例如: "1.02 GB")
    var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
    }
}

/*
// Test case
return SwapUsageInfo(
    total: 10 * 1024 * 1024 * 1024,
    used: UInt64(4.02 * 1024 * 1024 * 1024),
    free: UInt64(5.08 * 1024 * 1024 * 1024)
)
*/
