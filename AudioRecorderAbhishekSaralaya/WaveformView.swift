//
//  WaveformView.swift
//  AudioRecorderAbhishekSaralaya
//
//  Created by Abhishek Saralaya on 06/06/24.
//

import SwiftUI

import SwiftUI

struct WaveformView: View {
    var samples: [Float]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let middle = height / 2
            let sampleCount = samples.count
            let step = width / CGFloat(sampleCount)

            Path { path in
                path.move(to: CGPoint(x: 0, y: middle))
                for (index, sample) in samples.enumerated() {
                    let x = CGFloat(index) * step
                    let y = middle - CGFloat(sample) * middle
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.blue, lineWidth: 1)
        }
    }
}

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView(samples: Array(repeating: 0.5, count: 100))
            .frame(height: 100)
    }
}
