//
//  PathManager.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/26/25.
//

import UIKit
import NMapsMap

final class PathManager {
    
    // MARK: - Properties
    private let pathOverlay = NMFPath()
    private let innerPathOverlay = NMFPath() // 안쪽 테두리용
    private var pathCoordinates: [NMGLatLng] = []
    private weak var mapView: NMFMapView?
    
    // MARK: - Initialization
    init(mapView: NMFMapView) {
        self.mapView = mapView
        setupPathOverlays()
    }
    
    deinit {
        print("🛣️ PathManager deinit 시작")
        cleanupResources()
    }
    
    // MARK: - Cleanup
    private func cleanupResources() {
        // 오버레이들을 지도에서 제거
        pathOverlay.mapView = nil
        innerPathOverlay.mapView = nil
        
        // 좌표 배열 정리
        pathCoordinates.removeAll()
        
        // 지도 뷰 참조 해제 (weak 참조이므로 nil 할당 가능)
        mapView = nil
        
        print("✅ PathManager 리소스 정리 완료")
    }
    
    // MARK: - Setup
    private func setupPathOverlays() {
        // 안쪽 경로선 설정
        pathOverlay.width = 13 // 전체 경로선 너비도 늘려서 마커와 겹치도록
        pathOverlay.color = .white
        
        // 바깥쪽 테두리 설정
        pathOverlay.outlineWidth = 1
        pathOverlay.outlineColor =  UIColor(hex: "#738496")
        
        // 메인 경로선 설정
        innerPathOverlay.width = 8 // 경로선 너비를 늘려서 마커와 겹치도록
        innerPathOverlay.color = UIColor(hex: "#00E1FF")
        innerPathOverlay.outlineWidth = 0
        
        // 패턴 이미지 설정
        if let patternImage = UIImage(named: "pattern") {
            innerPathOverlay.patternIcon = NMFOverlayImage(image: patternImage)
            innerPathOverlay.patternInterval = 16 // 패턴 간격
        } else {
            print("❌ 패턴 이미지 로드 실패: pattern")
        }
        
        // 경로선들을 지도에 추가
        pathOverlay.mapView = mapView
        innerPathOverlay.mapView = mapView
        print("✅ 경로선 지도에 추가 완료")
    }
    
    // MARK: - Public Methods
    func addCoordinate(_ coordinate: NMGLatLng) {
        pathCoordinates.append(coordinate)
        drawPath()
    }
    
    func setCoordinates(_ coordinates: [NMGLatLng]) {
        pathCoordinates = coordinates
        drawPath()
    }
    
    func clearPath() {
        pathCoordinates.removeAll()
        pathOverlay.mapView = nil
        innerPathOverlay.mapView = nil
    }
    
    func getPathCoordinates() -> [NMGLatLng] {
        return pathCoordinates
    }
    
    // MARK: - Private Methods
    private func drawPath() {
        guard pathCoordinates.count >= 2 else {
            print("❌ 경로선 그리기 실패: 좌표가 2개 미만 (\(pathCoordinates.count))")
            return
        }
        
        print("✅ 경로선 그리기 시작: \(pathCoordinates.count)개 좌표")
        
        // 경로선을 지도에서 제거 후 다시 추가
        pathOverlay.mapView = nil
        innerPathOverlay.mapView = nil
        
        let path = NMGLineString(points: pathCoordinates)
        print("✅ 경로 생성 완료: \(path.points.count)개 포인트")
        
        // 타입 캐스팅을 사용하여 안전하게 할당
        if let typedPath = path as? NMGLineString<AnyObject> {
            pathOverlay.path = typedPath
            innerPathOverlay.path = typedPath
            print("✅ 경로선 타입 캐스팅 성공")
            
            // 경로선 설정 후 패턴과 윤곽선 다시 적용
            applyPathStyling()
        } else {
            // 타입 캐스팅이 실패한 경우 경로선만 다시 추가
            pathOverlay.mapView = mapView
            innerPathOverlay.mapView = mapView
            print("❌ 경로선 타입 캐스팅 실패")
        }
        
        // 경로선을 다시 지도에 추가
        pathOverlay.mapView = mapView
        innerPathOverlay.mapView = mapView
        print("✅ 경로선 지도에 추가 완료")
    }
    
    private func applyPathStyling() {
        // 안쪽 경로선 스타일 재설정
        pathOverlay.width = 13 // 전체 경로선 너비도 늘려서 마커와 겹치도록
        pathOverlay.color = .white
        
        // 바깥쪽 테두리 재설정
        pathOverlay.outlineWidth = 1
        pathOverlay.outlineColor = UIColor(hex: "#738496")
        
        // 메인 경로선 스타일 재설정
        innerPathOverlay.width = 8 // 경로선 너비를 늘려서 마커와 겹치도록
        innerPathOverlay.color = UIColor(hex: "#00E1FF")
        innerPathOverlay.outlineWidth = 0
        
        // 패턴 이미지 재설정
        if let patternImage = UIImage(named: "pattern") {
            innerPathOverlay.patternIcon = NMFOverlayImage(image: patternImage)
            innerPathOverlay.patternInterval = 16 // 패턴 간격
            print("✅ 패턴 재설정 완료 (pattern)")
        } else {
            print("❌ 패턴 이미지 로드 실패: pattern")
        }
        
        print("✅ 경로선 스타일 재설정 완료")
    }
}
