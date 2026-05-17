//
//  NandaPressure.swift
//  RsMemPeeker
//
//  Created by Rahnoc on 2026/5/17.
//

import Foundation



// 根據實體記憶體大小分類。
enum DeviceCapibilityType {
    case mem8
    case mem16
    case mem24up
    
    
    /// 根據 記憶體總量 分類機器。
    /// - Parameter ram: 大致分為 8 / 16 / 24以上。
    /// - Returns: 記憶體總量的分類屬於哪群
    static func findDevice(ram: Double) -> Self {
        // +0.5 為保險。
        if ram <= 8.5 {
            return .mem8
        } else if ram <= 16.5 {
            return .mem16
        } else {
            return .mem24up
        }
    }
    
    
    /// 針對不同 記憶體總量 機器的 page-out 的嚴重指摽數值分界。 單位為 MB/s。
    /// 註：此標準基於「5秒平均值」，用以捕捉持續性的記憶體壓力，避免單次觸發的誤報。
    var pageOutBounds: (warn: Double, crit: Double) {
        switch self {
            // 針對 8G 機型 (如 Air M3 8G)：硬碟較慢、RAM極小，稍微持續置換就該注意
            // > 超過 10 MB/s 算輕微勉強
            // > 超過 40 MB/s 算嚴重危險
            case .mem8:     return (10.0, 40.0)
            
            // 針對 16G 機型
            // > 超過 25 MB/s 算輕微勉強，記憶體剛好用完
            // > 超過 90 MB/s 算嚴重危險，核心工作負載已嚴重溢出
        case .mem16:    return (25.0, 90.0)
            
            // 針對 24G/32G 以上高階機型 (如 Air M5 24G)：硬碟極快且RAM大，容忍度極高
            // > 正常不應該有 page-out，一旦有往往是大型運算或 Memory Leak
            // > 超過 50 MB/s 算輕微勉強
            // > 超過 180 MB/s 算嚴重危險，程式可能暴走
            case .mem24up:  return (50.0, 180.0)
        }
    }
    
    /// 針對不同 記憶體總量 機器的 swap用量 的嚴重指摽數值分界。 單位為GB。
    var swapBounds: (warn: Double, crit: Double) {
        switch self {
        case .mem8:     return (3.0, 6.0)
        case .mem16:    return (6.0, 12.0)
        case .mem24up:  return (10.0, 20.0)
        }
    }
    
    // -----------------
    //
    // ----------------
    
    /// 機器種類的 記憶體大小字串(附單位)。
    var memString: String {
        switch self {
        case .mem8:     return "8GB"
        case .mem16:    return "16GB"
        case .mem24up:  return "24GB+"
        }
    }
    
    
    // -----------------
    // Mock 亂取用邊界
    // -----------------
    
    /// 取得 mock 用的 交換檔大小 (GB) 亂取範圍。
    static func getMockSwapRndBoundary(target: Self) -> Double {
        switch target {
        case .mem8: 16
        case .mem16: 24
        case .mem24up: 32
        }
    }
    
    /// 取得 mock 用的 page out (MB/s) 的亂取範圍。
    static func getPageOutRndBoundary(targt: Self) -> Double {
        switch targt {
        case .mem8: 54.0
        case .mem16: 110.0
        case .mem24up: 220.0
        }
    }
    
}


// Page-out 寫入硬碟的威脅程度 描述用。
enum PageOutLevel: String {
    case ok         = "気のせいか……"
    case warning    = "何だ、このプレッシャーは！？"
    case critical   = "まだだ！まだ終わらんよ！"
}



// Page-out 的
struct NandaPressure {
    // 硬體資訊
    let totalRAMBytes: UInt64
    let totalRAMGB: Double
    
    // 根據機型動態設定 Page-out 的危險臨界值 (MB/s)
    let criticalPageoutThreshold: Double
    let warningPageoutThreshold: Double
    
    // 目標設備
    let devCap: DeviceCapibilityType
    
    
    // -------------
    
    // mockAs 非 nil 時，根據 mock目標定時亂取當作資訊。
    init(mockAs: DeviceCapibilityType?=nil) {
        // 自動偵測當前 Mac 的實體記憶體總量
        totalRAMBytes = ProcessInfo.processInfo.physicalMemory
        totalRAMGB = Double(totalRAMBytes) / (1024 * 1024 * 1024)
        
        
        if let target = mockAs {
            // A. 使用 mock:
            devCap = target
            print( "Target Device MEM: \(devCap.memString) (mock)" )
        }else{
            // B. 針對實機: 用偵測到的記憶體總量去比對
            devCap = DeviceCapibilityType.findDevice(ram: totalRAMGB)
            print( "Target Device MEM: \(Int(totalRAMGB))GB (phys)" )
        }
        
        // 根據 目標機器記憶體總量 來設定危險臨界值。
        let bounds = devCap.pageOutBounds
        warningPageoutThreshold = bounds.warn
        criticalPageoutThreshold = bounds.crit
        
    }
    

    // 監控邏輯中使用這套動態閾值
    func evaluateSystemStatus(averagePageoutMB: Double) -> PageOutLevel {
        if averagePageoutMB > criticalPageoutThreshold {
            return .critical
        } else if averagePageoutMB > warningPageoutThreshold {
            return .warning
        } else {
            return .ok
        }
    }
    
    
    // ------------
    
    // 取得 page-out 顯示用資料
    func getPageoutInfo(averagePageoutMB: Double) -> (avgPoDesc: String, poLevel: PageOutLevel) {
        let avgPo = String(format: "%.2f MB/s", averagePageoutMB)
        let poLevel = evaluateSystemStatus(averagePageoutMB: averagePageoutMB)
        
        return (avgPo, poLevel)
    }
}
