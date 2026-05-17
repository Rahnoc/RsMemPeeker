//
//  RsMemPeekerApp.swift
//  RsMemPeeker
//
//  Created by Rahnoc on 2025/12/19.
//

import SwiftUI



@main
struct RsMemPeekerApp: App {
    // 為 nil 時：即時抓實機資料。 非 nil 時：模擬目標機種，並亂取資訊。
    static var mockAs: DeviceCapibilityType? = nil
    
    @State private var mMnt = MemoryMonitor(mockAs: mockAs)
    @State private var pMnt = PageMemoryMonitor(mockAs: mockAs)
    @State private var sMnt = SystemMonitor()
    private var nPrs = NandaPressure(mockAs: mockAs)
    
    
    // 這會自動將設定儲存在 UserDefaults 中
    @AppStorage("showTextInMenuBar") private var showStorageText: Bool = false
    //@State private var showStorageText: Bool = false

    
    // 取得主要版本號 (例如: 1.0.2)
    private var releaseVersionNumber: String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    // 取得編譯版本號 (例如: 123)
    private var buildVersionNumber: String? {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }
    private var version:String {
        return "\(releaseVersionNumber ?? "1.0.0") (\(buildVersionNumber ?? "-"))"
    }
    
    
    
    
    var body: some Scene {
        // 顯示在選單列上的文字標籤
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 8) {
                let memCategoryStr: String = {
                    if (Self.mockAs != nil) {
                        "模擬\(nPrs.devCap.memString)"
                    }else{
                        "\(Int(nPrs.totalRAMGB))GB"
                    }
                }()
                HStack(alignment: .bottom, spacing: 2) {
                    // * 關於
                    Button("[ Rs流監控 v\(version) ]") {
                        // ignoringOtherApps: true 會讓 App 即使沒有 Dock 圖示也能跳出來
                        NSApp.activate(ignoringOtherApps: true)
                        // 上面的不行時，再加。
                        /*
                         NSApp.orderFrontStandardAboutPanel(
                         options: [NSApplication.AboutPanelOptionKey(rawValue: "Hierarchy"): 1]
                         )
                         */
                        
                        // 呼叫系統標準的關於面板
                        //NSApp.orderFrontStandardAboutPanel(nil)
                        // 使用info那邊的plist
                        //NSApplication.shared.orderFrontStandardAboutPanel(nil)
                        
                        
                        // 顯示自訂字串到 about 裡:
                        let customText = "「まだだ！まだ終わらんよ！」"
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .center
                        // 包裝成系統要的 NSAttributedString
                        let attributes: [NSAttributedString.Key: Any] = [
                            .paragraphStyle: paragraphStyle,
                            .foregroundColor: NSColor.labelColor // 確保文字顏色適應深色/淺色模式
                        ]
                        let creditsString = NSAttributedString(string: customText, attributes: attributes)
                        // 呼叫並傳入 options 字典
                        NSApplication.shared.orderFrontStandardAboutPanel(options: [
                            .credits: creditsString
                        ])
                        
                    }
                    .buttonStyle(.accessoryBar)
                    .foregroundStyle(.indigo)
                    
                    Spacer()
                    
                    // 當前目標(/模擬)機型的記憶體大小資訊。
                    Text("\(memCategoryStr)")
                        .foregroundStyle(.tertiary)
                        .textScale(.secondary)
                }
                
                
                Divider()
                
                
                // 計算 page-out 相關訊息
                let poInfo: (avgPoDesc: String, poLevel: PageOutLevel) = {
                    nPrs.getPageoutInfo(averagePageoutMB: pMnt.averagePageoutsPerSecondMB)
                }()
                
                // 動態切換標籤文字的顏色
                let levelTextColor: Color = {
                    switch poInfo.poLevel {
                    case .ok: return .secondary
                    case .warning: return .orange // 這裡建議用 orange 對比比較明顯
                    case .critical: return .red
                    }
                }()
                
                // 動態切換底色（ok 深灰、warning 淡黃、critical 深紅）
                let levelBgColor: Color = {
                    switch poInfo.poLevel {
                    case .ok:
                        return Color(white: 0.25) // 深灰色
                    case .warning:
                        return Color.yellow.opacity(0.3) // 淡黃色
                    case .critical:
                        return Color(red: 0.55, green: 0.05, blue: 0.05) // 深紅
                    }
                }()
                
                
                // * 墨鏡感應台詞
                // 墨鏡狀態標籤（強制在 VStack 中水平居中）
                HStack {
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: "sunglasses.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(poInfo.poLevel == .warning ? .black : .white) // 淡黃底配黑墨鏡，深色底配白墨鏡
                        
                        Text("「\(poInfo.poLevel.rawValue)」")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(levelTextColor)
                    }
                    .padding(.horizontal, 4)    // 左右留空隙
                    .padding(.vertical, 4)      // 上下留空隙
                    .background(levelBgColor)
                    .clipShape(Capsule())
                    Spacer()
                }
                .padding(.vertical, 4)
                
                
                Divider()
                
                // * 記憶體相關資訊
                // Memory 記憶體壓力 監控
                // 將 Label 拆開為 HStack 以精準控制圖示大小與對齊
                HStack(spacing: 4) {
                    Image(systemName: "memorychip")
                        .font(.system(size: 12))
                        .frame(width: 16, alignment: .center)
                        .foregroundColor(mMnt.pLevel.color)
                    
                    Text("記憶體壓力:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(mMnt.pLevel.description)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(mMnt.pLevel.color)
                }
                
                // Page-out 監控
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.to.line.compact")
                        .font(.system(size: 12))
                        .frame(width: 16, alignment: .center)
                        .foregroundColor(levelTextColor)
                    
                    Text("PageOut:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(poInfo.avgPoDesc)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(levelTextColor)
                }
                
                // Swap 監控
                if let swap = mMnt.swapInfo {
                    HStack(spacing: 4) {
                        
                        let swapColor: Color = {
                            if swap.used > UInt64(nPrs.devCap.swapBounds.crit) * 1024 * 1024 * 1024 {
                                return Color(red: 0.75, green: 0.15, blue: 0.15) // Critical: 深紅色
                            } else if swap.used > UInt64(nPrs.devCap.swapBounds.warn) * 1024 * 1024 * 1024 {
                                return .orange // Warning: 橘色
                            } else {
                                return .secondary
                            }
                        }()
                        
                        Image(systemName: "arrow.left.and.right.square")
                            .font(.system(size: 12))
                            .frame(width: 16, alignment: .center)
                            .foregroundColor(swapColor)
                        
                        Text("Swap 使用:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(swap.usedFormatted)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(swapColor)
                    }
                }
                
                
                Button("開啟 活動監視器") {
                    openActivityMonitor()
                    NSApp.keyWindow?.orderOut(nil)
                    NSApp.deactivate()
                }
                .buttonStyle(.borderedProminent)
                
                
                Divider()
                
                // * Storage:
                HStack(spacing: 4) {
                    Label("硬碟剩餘:", systemImage: "internaldrive")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(sMnt.freeDiskSpace)")
                        .monospaced()
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Toggle("顯示於選單列", isOn: $showStorageText)
                        .toggleStyle(.automatic)
                    
                    Spacer()
                    
                    Button(action: {
                        sMnt.updateData()
                    }) {
                        HStack {
                            if sMnt.isRefreshing {
                                ProgressView() // 轉圈動畫
                                    .controlSize(.small)
                                    .padding(.trailing, 2)
                            }
                            Text(sMnt.isRefreshing ? "讀取中..." : "更新顯示")
                        }
                    }
                    .disabled(sMnt.isRefreshing) // 當正在刷新時，直接鎖定按鈕
                }
                
                Button("開啟 硬碟用量") {
                    openSysDiskUsage()
                    NSApp.keyWindow?.orderOut(nil)
                    NSApp.deactivate() 
                }
                    .buttonStyle(.borderedProminent)
                
                
                Divider()
                
                // * Sys:
                Button("結束程式") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
            .frame(width: 250)
            .onAppear {
                // 1. 強制將 App 提升到最前方，並無視其他正在使用的軟體
                NSApp.activate(ignoringOtherApps: true)
            }
            
            
        } label: {
            // 選單列上的圖示/文字，會隨 monitor 狀態更新
            HStack(spacing: 4) {
                // 根據壓力感變顏色
                Image(systemName: "memorychip")
                    .symbolRenderingMode(.palette)
                    .foregroundColor( mMnt.pLevel.color )
                
                if showStorageText {
                    // 顯示硬碟剩餘空間
                    Text (sMnt.freeDiskSpace )
                        .controlSize(.mini)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
        
    }
    
    
    // --------------
    
    // 使用現代 API 開啟「活動監視器」
    func openActivityMonitor() {
        let workspace = NSWorkspace.shared
        let appURL = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        
        workspace.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { (app, error) in
            if let error = error {
                print("無法開啟活動監視器: \(error.localizedDescription)")
            }
        }
    }
    
    // 開啟 系統資訊>一般>儲存空間
    func openSysDiskUsage() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.Storage") {
            NSWorkspace.shared.open(url)
        }
    }
}
