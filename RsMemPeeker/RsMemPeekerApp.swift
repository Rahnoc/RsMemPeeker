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
        return "\(releaseVersionNumber ?? "1.0") (\(buildVersionNumber ?? "1"))"
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
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
                .buttonStyle(.accessoryBar)
                
                
                Divider()
                
                // Memory:
                Label("記憶體壓力: \(mMnt.pLevel.description)", systemImage: "memorychip")
                    .foregroundColor( mMnt.pLevel.color )
                Button("開啟 活動監視器") {openActivityMonitor()}
                    .buttonStyle(.borderedProminent)
                
                Divider()
                
                // Storage:
                Label("硬碟剩餘: \(sMnt.freeDiskSpace)", systemImage: "internaldrive")
                Toggle("顯示於選單列", isOn: $showStorageText)
                    .toggleStyle(.automatic)
                Button("更新顯示") { sMnt.updateData() }
                Button("開啟 硬碟用量") {openSysDiskUsage()}
                    .buttonStyle(.borderedProminent)
                
                Divider()
                
                // Sys:
                Button("結束程式") {
                    NSApplication.shared.terminate(nil)
                }
            }
            //.frame(width: 220)
            .padding()
            
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
