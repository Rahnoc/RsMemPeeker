//
//  SwapUsageInfo.swift
//  RsMemPeeker
//
//  Created by Rahnoc on 2026/5/16.
//


import Foundation



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

func getSwapUsage() -> SwapUsageInfo? {
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


/*
// Test case
return SwapUsageInfo(
    total: 10 * 1024 * 1024 * 1024,
    used: UInt64(4.02 * 1024 * 1024 * 1024),
    free: UInt64(5.08 * 1024 * 1024 * 1024)
)
*/

/*
// 使用範例：
if let swap = getSwapUsage() {
    print("目前 Swap 已使用：\(swap.usedFormatted)")
}
*/
