//
//  GIFView.swift
//  Tourding_FE
//
//  Created by 이유현 on 9/15/25.
//

import SwiftUI
import UIKit
import ImageIO

// gif 파일을 swiftUI에서 사용
struct GIFView: UIViewRepresentable {
    let name: String

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let gifView = GIFImageView()
        gifView.loadGif(name: name)
        
        containerView.addSubview(gifView)
        gifView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            gifView.topAnchor.constraint(equalTo: containerView.topAnchor),
            gifView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            gifView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            gifView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 업데이트할 내용 없음
    }
}

// MARK: - GIFImageView
class GIFImageView: UIImageView {
    private var frames: [UIImage] = []
    private var frameDurations: [Double] = []
    private var displayLink: CADisplayLink?
    private var currentFrameIndex = 0
    private var accumulator: Double = 0.0
    private var totalDuration: Double = 0.0

    func loadGif(name: String) {
        self.contentMode = .scaleAspectFill  // scaleAspectFit 대신 scaleAspectFill 사용
        self.clipsToBounds = true
        
        guard let path = Bundle.main.path(forResource: name, ofType: "gif") else {
            print("❌ GIF 파일을 찾을 수 없습니다: \(name).gif")
            return
        }
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("❌ GIF 파일 데이터를 읽을 수 없습니다: \(name).gif")
            return
        }
        
        print("✅ GIF 파일 로드 성공: \(name).gif")
        parseGif(data: data)
        startAnimation()
    }

    private func parseGif(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }
        let count = CGImageSourceGetCount(source)

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                frames.append(UIImage(cgImage: cgImage))
            }

            let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any]
            let gifInfo = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
            let delay = (gifInfo?[kCGImagePropertyGIFUnclampedDelayTime] as? Double) ??
                        (gifInfo?[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.1
            frameDurations.append(delay)
            totalDuration += delay
        }
    }

    private func startAnimation() {
        guard !frames.isEmpty else { return }
        self.image = frames[0]
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateFrame() {
        guard !frames.isEmpty else { return }
        accumulator += displayLink?.duration ?? 0

        while accumulator >= frameDurations[currentFrameIndex] {
            accumulator -= frameDurations[currentFrameIndex]
            currentFrameIndex = (currentFrameIndex + 1) % frames.count
            self.image = frames[currentFrameIndex]
        }
    }

    deinit {
        displayLink?.invalidate()
    }
}

//MARK: - 사용법
/*
 struct ContentView: View {
     var body: some View {
        GIFView(name: "example") // example.gif
             .frame(width: 200, height: 200)
     }
 }
 */
