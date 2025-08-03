//
//  NaverMapView.swift
//  Tourding_FE
//
//  Created by 이유현 on 7/24/25.
//

import SwiftUI
import NMapsMap

struct NaverMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView(frame: .zero)
        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {
        // SwiftUI 상태 값에 따라 업데이트가 필요하면 여기에 작성
    }
}
