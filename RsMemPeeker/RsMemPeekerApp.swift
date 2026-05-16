//
//  RsMemPeekerApp.swift
//  RsMemPeeker
//
//  Created by Rahnoc on 2025/12/19.
//

import SwiftUI

@main
struct RsMemPeekerApp: App {
    @State private var mMnt = MemoryMonitor()
    @State private var sMnt = SystemMonitor()
    
    
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
        return "\(releaseVersionNumber ?? "1.0") (\(buildVersionNumber ?? "5"))"
    }
    
    
    
    
    var body: some Scene {
        // 顯示在選單列上的文字標籤
        MenuBarExtra {
            VStack(alignment: .leading) {
                // 關於:
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
                
                
                Divider()
                
                // Memory:
                Label("記憶體壓力: \(mMnt.pLevel.description)", systemImage: "memorychip")
                    .foregroundColor( mMnt.pLevel.color )
                
                // Swap 監控：每 5 秒安全重新算一次，只有大於 0 時才高亮提示
                if let swap = mMnt.swapInfo {
                    HStack(spacing: 8) {
                        Label("Swap 使用:", systemImage: "arrow.left.and.right.square")
                            .foregroundColor(.secondary) 
                        
                        // 建立一個動態變數來計算顏色
                        let swapColor: Color = {
                            if swap.used == 0 {
                                return .secondary // 0 bytes 顯示穩重灰
                            } else if swap.used > 5 * 1024 * 1024 * 1024 {
                                return .red       // 超過 5 GB 顯示危險紅（數字可依需求調整）
                            } else {
                                return .orange    // 介於中間顯示警告橘
                            }
                        }()
                        
                        Text(swap.usedFormatted)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(swapColor)
                    }
                    .padding(.top, 2)
                }
                Button("開啟 活動監視器") {
                    openActivityMonitor()
                    NSApp.keyWindow?.orderOut(nil)
                    NSApp.deactivate()
                }
                .buttonStyle(.borderedProminent)
                
                
                Divider()
                
                // Storage:
                Label("硬碟剩餘: \(sMnt.freeDiskSpace)", systemImage: "internaldrive")
                Toggle("顯示於選單列", isOn: $showStorageText)
                    .toggleStyle(.automatic)
                Button("更新顯示") { sMnt.updateData() }
                Button("開啟 硬碟用量") {
                    openSysDiskUsage()
                    NSApp.keyWindow?.orderOut(nil)
                    NSApp.deactivate() 
                }
                    .buttonStyle(.borderedProminent)
                
                Divider()
                
                // Sys:
                Button("結束程式") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
            .frame(width: 220)
            
            
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
        
        
        /*
        WindowGroup {
            ContentView()
        }
        */
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
