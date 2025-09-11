//
//  NetworkMonitor.swift
//  Tourding_FE
//
//  Created by AI Assistant on 2025-01-27.
//

import Foundation
import Network
import Combine

/// 네트워크 연결 상태를 모니터링하는 클래스
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    /// 네트워크 모니터링 시작
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    /// 네트워크 상태 업데이트
    private func updateNetworkStatus(_ path: NWPath) {
        isConnected = path.status == .satisfied
        connectionType = path.availableInterfaces.first?.type
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        let statusMessage = isConnected ? "연결됨" : "연결 안됨"
        let typeMessage = connectionType?.description ?? "알 수 없음"
        
        print("🌐 네트워크 상태: \(statusMessage) (\(typeMessage))")
        
        if isExpensive {
            print("⚠️ 데이터 요금제 사용 중")
        }
        
        if isConstrained {
            print("⚠️ 제한된 네트워크 환경")
        }
    }
    
    /// 네트워크 연결 상태 확인
    var isNetworkAvailable: Bool {
        return isConnected
    }
    
    /// WiFi 연결 여부 확인
    var isWiFiConnected: Bool {
        return isConnected && connectionType == .wifi
    }
    
    /// 셀룰러 연결 여부 확인
    var isCellularConnected: Bool {
        return isConnected && connectionType == .cellular
    }
    
    /// 네트워크 상태에 따른 사용자 메시지
    var networkStatusMessage: String {
        if !isConnected {
            return "인터넷 연결을 확인해주세요."
        }
        
        if isExpensive {
            return "데이터 요금제 사용 중입니다."
        }
        
        if isConstrained {
            return "네트워크 연결이 제한적입니다."
        }
        
        return "네트워크 연결됨"
    }
}

// MARK: - NWInterface.InterfaceType Extension
extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "셀룰러"
        case .wiredEthernet:
            return "이더넷"
        case .loopback:
            return "로컬"
        case .other:
            return "기타"
        @unknown default:
            return "알 수 없음"
        }
    }
}
