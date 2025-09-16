//
//  MarkerIcons.swift
//  Tourding_FE
//
//  Created by 이유현 on 8/26/25.
//

import NMapsMap
import UIKit

enum MarkerIcons {
    
    static let startMarker = NMFOverlayImage(name: "startMarker")
    static let goalMarker = NMFOverlayImage(name: "goalMarker")
    
    // 길찾기 가이드
    static let leftMarker = NMFOverlayImage(name: "leftMarker")
    static let rightMarker = NMFOverlayImage(name: "rightMarker")
    static let straightMarker = NMFOverlayImage(name: "straightMarker")
    static let stopoverMarker = NMFOverlayImage(name: "stopoverMarker")
    static let crossingMarker = NMFOverlayImage(name: "crossingMarker")
    
    // 토글 마커
    static let csMarker = NMFOverlayImage(name: "csMarker")
    static let toiletMarker = NMFOverlayImage(name: "toiletMarker")
    
    // 유저 현재 위치
    static let userMarker = NMFOverlayImage(name:"userMarker")
    
    // 검정색 원형 마커에 흰색 숫자 생성
    static func numberMarker(_ number: Int) -> NMFOverlayImage {
        let size = CGSize(width: 21, height: 21)
        
        let containerView = UIView(frame: CGRect(origin: .zero, size: size))
        containerView.backgroundColor = .clear
        
        // 검정색 원형 배경
        let circleView = UIView(frame: containerView.bounds)
        circleView.backgroundColor = .black
        circleView.layer.cornerRadius = size.width / 2
        circleView.layer.borderWidth = 3
        circleView.layer.borderColor = UIColor.white.cgColor
        
        
        // 흰색 숫자 레이블
        let numberLabel = UILabel()
        numberLabel.text = "\(number)"
        numberLabel.textColor = .white
        numberLabel.font = UIFont.boldSystemFont(ofSize: 10.5)
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(circleView)
        containerView.addSubview(numberLabel)
        
        // 레이블을 중앙에 배치
        NSLayoutConstraint.activate([
            numberLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        // UIView를 UIImage로 변환
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            containerView.layoutIfNeeded()
            containerView.layer.render(in: context.cgContext)
        }
        
        return NMFOverlayImage(image: image)
    }
    
    // 마커 타입을 구분하는 함수 (업데이트)
    static func getMarkerType(for icon: NMFOverlayImage) -> MarkerType {
        if icon === startMarker { return .startMarker }
        if icon === goalMarker { return .goalMarker }
        
        if icon === leftMarker { return .leftMarker }
        if icon === rightMarker { return .rightMarker }
        if icon === straightMarker { return .straightMarker }
        if icon === stopoverMarker {return .stopoverMarker}
        if icon === crossingMarker {return .crossingMarker}
        
        if icon === csMarker { return .csMarker }
        if icon === toiletMarker { return .toiletMarker }
        
        if icon === userMarker { return .userMarker }
        return .numberMarker // 숫자 마커는 구분하기 어려우므로 numberMarker로 처리
    }
    
    enum MarkerType {
        case startMarker, goalMarker,
             leftMarker, rightMarker, straightMarker, stopoverMarker, crossingMarker,
             csMarker, toiletMarker,
             userMarker, numberMarker, unknown
    }
}

