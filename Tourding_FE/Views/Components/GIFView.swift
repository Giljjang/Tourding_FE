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

    func makeUIView(context: Context) -> GIFImageView {
        let gifView = GIFImageView()
        gifView.loadGif(name: name)
        return gifView
    }

    func updateUIView(_ uiView: GIFImageView, context: Context) {}
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
        guard let path = Bundle.main.path(forResource: name, ofType: "gif"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
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
