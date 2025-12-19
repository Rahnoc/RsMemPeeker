//
//  MemoryMonitor.swift
//  RsMemPeeker
//
//  Created by Rahnoc on 2025/12/19.
//


import SwiftUI

// 針對記憶體顯示


@Observable
class MemoryMonitor {
    var pressureLevel: Int32 = -1
    private var timer: Timer?

    var pLevel: MemPreLevel {
        get {
            MemPreLevel.convert(num: pressureLevel)
        }
    }
    
    
    init() {
        start()
    }

    func start() {
        // 首次執行
        self.pressureLevel = self.getMemoryPressure()
        
        // 每 5 秒更新一次
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.pressureLevel = self?.getMemoryPressure() ?? -1
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
    
}


// 記憶體壓力等級
public enum MemPreLevel: CustomStringConvertible {
    case unknow
    case normal
    case warning
    case critical
    
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
