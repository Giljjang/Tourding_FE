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
        innerPathOverlay.color = UIColor(hex: "#2C333A")
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
//        print("✅ 경로선 지도에 추가 완료")
    }
    
    // MARK: - Public Methods
    func addCoordinate(_ coordinate: NMGLatLng) {
        pathCoordinates.append(coordinate)
        drawPath()
    }
    
    func setCoordinates(_ coordinates: [NMGLatLng]) {
        // 메모리 사용량 로깅
        let originalCount = coordinates.count
        print("🛣️ 경로선 좌표 최적화 시작: 원본 \(originalCount)개")
        
        // 메모리 최적화: 경로선 좌표 단순화
        pathCoordinates = simplifyPathCoordinates(coordinates)
        
        let optimizedCount = pathCoordinates.count
        let reductionRate = originalCount > 0 ? Double(originalCount - optimizedCount) / Double(originalCount) * 100 : 0
        print("🛣️ 경로선 좌표 최적화 완료: \(optimizedCount)개 (약 \(String(format: "%.1f", reductionRate))% 감소)")
        
        drawPath()
    }
    
    // 경로선 좌표 단순화 (메모리 최적화)
    private func simplifyPathCoordinates(_ coordinates: [NMGLatLng]) -> [NMGLatLng] {
        guard coordinates.count > 2 else { return coordinates }
        
        // Douglas-Peucker 알고리즘을 사용한 경로선 단순화
        let tolerance: Double = 0.00001 // 약 1미터 정도의 허용 오차
        return douglasPeucker(coordinates, tolerance: tolerance)
    }
    
    // Douglas-Peucker 알고리즘 구현
    private func douglasPeucker(_ points: [NMGLatLng], tolerance: Double) -> [NMGLatLng] {
        guard points.count > 2 else { return points }
        
        // 첫 번째와 마지막 점 사이의 거리가 허용 오차보다 작으면 단순화
        if points.count <= 3 {
            return points
        }
        
        // 가장 먼 점 찾기
        var maxDistance = 0.0
        var maxIndex = 0
        
        let firstPoint = points[0]
        let lastPoint = points[points.count - 1]
        
        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(points[i], lineStart: firstPoint, lineEnd: lastPoint)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        // 허용 오차보다 큰 거리가 있으면 재귀적으로 분할
        if maxDistance > tolerance {
            let leftPoints = Array(points[0...maxIndex])
            let rightPoints = Array(points[maxIndex..<points.count])
            
            let leftSimplified = douglasPeucker(leftPoints, tolerance: tolerance)
            let rightSimplified = douglasPeucker(rightPoints, tolerance: tolerance)
            
            // 중복 제거 (마지막 점과 첫 번째 점이 같을 수 있음)
            return leftSimplified + Array(rightSimplified.dropFirst())
        } else {
            // 허용 오차 내에 있으면 첫 번째와 마지막 점만 반환
            return [firstPoint, lastPoint]
        }
    }
    
    // 점과 선 사이의 수직 거리 계산
    private func perpendicularDistance(_ point: NMGLatLng, lineStart: NMGLatLng, lineEnd: NMGLatLng) -> Double {
        let A = point.lat - lineStart.lat
        let B = point.lng - lineStart.lng
        let C = lineEnd.lat - lineStart.lat
        let D = lineEnd.lng - lineStart.lng
        
        let dot = A * C + B * D
        let lenSq = C * C + D * D
        
        if lenSq == 0 {
            return sqrt(A * A + B * B)
        }
        
        let param = dot / lenSq
        
        var xx: Double, yy: Double
        
        if param < 0 {
            xx = lineStart.lat
            yy = lineStart.lng
        } else if param > 1 {
            xx = lineEnd.lat
            yy = lineEnd.lng
        } else {
            xx = lineStart.lat + param * C
            yy = lineStart.lng + param * D
        }
        
        let dx = point.lat - xx
        let dy = point.lng - yy
        
        return sqrt(dx * dx + dy * dy)
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
        
//        print("✅ 경로선 그리기 시작: \(pathCoordinates.count)개 좌표")
        
        // 경로선을 지도에서 제거 후 다시 추가
        pathOverlay.mapView = nil
        innerPathOverlay.mapView = nil
        
        let path = NMGLineString(points: pathCoordinates)
//        print("✅ 경로 생성 완료: \(path.points.count)개 포인트")
        
        // 타입 캐스팅을 사용하여 안전하게 할당
        if let typedPath = path as? NMGLineString<AnyObject> {
            pathOverlay.path = typedPath
            innerPathOverlay.path = typedPath
//            print("✅ 경로선 타입 캐스팅 성공")
            
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
//        print("✅ 경로선 지도에 추가 완료")
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
        innerPathOverlay.color = UIColor(hex: "#2C333A")
        innerPathOverlay.outlineWidth = 0
        
        // 패턴 이미지 재설정
        if let patternImage = UIImage(named: "pattern") {
            innerPathOverlay.patternIcon = NMFOverlayImage(image: patternImage)
            innerPathOverlay.patternInterval = 16 // 패턴 간격
//            print("✅ 패턴 재설정 완료 (pattern)")
        } else {
            print("❌ 패턴 이미지 로드 실패: pattern")
        }
        
//        print("✅ 경로선 스타일 재설정 완료")
    }
}
