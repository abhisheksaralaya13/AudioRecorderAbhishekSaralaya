//
//  AudioRecorder.swift
//  AudioRecorderAbhishekSaralaya
//
//  Created by Abhishek Saralaya on 06/06/24.
//
import Foundation
import AVFoundation
import SwiftUI

enum AudioRecodingState {
    case ready
    case recording
    case recorded
    case paused
}

struct File: Hashable {
    var url : URL
    var duration : TimeInterval
}

class AudioRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var audioEngine: AVAudioEngine!
    private var audioFile: AVAudioFile?
    private var audioSession: AVAudioSession!
    private var timer: Timer?
    var count = 0
    
    private var audioPlayer: AVAudioPlayer?
    
    @Published var recordingDuration: Int = 0
    @Published var recordingState: AudioRecodingState = AudioRecodingState.ready
    @Published var waveformSamples: [Float] = []
    @Published var isPlaying = false
    @Published var playbackDuration: Int = 0
    @Published var outputFileURL: URL!


    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try? audioSession.setActive(true)
    }

    func startRecording() {
        audioEngine = AVAudioEngine()
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        outputFileURL = documentURL.appendingPathComponent("recording\(Date.now.timeIntervalSince1970).caf")
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        do {
            audioFile = try AVAudioFile(forWriting: outputFileURL, settings: recordingFormat.settings)
        } catch {
            print("Failed to initialize audio file: \(error)")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.processAudioData(buffer: buffer)
            try? self.audioFile?.write(from: buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
            return
        }

        recordingState = .recording
        startTimer()
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        audioFile = nil
        stopTimer()
        recordingState = .recorded
    }

    func pauseRecording() {
        if recordingState == .recording {
            audioEngine.pause()
            recordingState = .paused
            stopTimer()
        }
    }

    func resumeRecording() {
        if recordingState == .paused {
            try? audioEngine.start()
            recordingState = .recording
            startTimer()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.recordingDuration += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func processAudioData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        // Downsample the data for visualization
        let samples = stride(from: 0, to: channelDataArray.count, by: 10).map { channelDataArray[$0] }
        count += 1
        print(count)
        DispatchQueue.main.async {
            self.waveformSamples = samples
        }
    }
    
    func startPlayback(url: URL?) {
        if url != nil {
            outputFileURL = url
        }
        guard let fileURL = outputFileURL else { return }
        do {
            // Initialize AVAudioPlayer and start playback
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            
            let audioFile = try AVAudioFile(forReading: fileURL)
            let sampleRate = audioFile.fileFormat.sampleRate
            
            // Calculate the number of samples to read for each segment
            let samplesPerSegment = Int(sampleRate) // Read one second of audio data
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                guard let audioPlayer = self.audioPlayer else { return }
                guard audioPlayer.isPlaying else {
                    self.isPlaying = false
                    timer.invalidate()
                    return
                }
                
                let currentTime = audioPlayer.currentTime
                let duration = audioPlayer.duration
                
                // Calculate the frame position to start reading audio data
                let startFrame = AVAudioFramePosition(currentTime * sampleRate)
                audioFile.framePosition = startFrame
                
                // Read audio data for one second
                let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(samplesPerSegment))
                try? audioFile.read(into: buffer!)
                
                // Process the audio data and update the waveform
                var waveformSamples: [Float] = []
                if let channelData = buffer?.floatChannelData {
                    for frame in 0..<Int(buffer!.frameLength) {
                        waveformSamples.append(channelData.pointee[frame])
                    }
                }
                self.waveformSamples = stride(from: 0, to: waveformSamples.count, by: 50).map { waveformSamples[$0] }
                self.playbackDuration = Int(self.audioPlayer?.currentTime ?? 0)
                // Check if playback is finished
                if self.audioPlayer?.isPlaying == false {
                    self.isPlaying = false
                    timer.invalidate()
                }
            }
        } catch {
            print("Failed to start playback: \(error)")
        }
    }


    
    func stopPlayback() {
        audioPlayer?.stop()
        stopTimer()
        isPlaying = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
    
    
    static func loadRecordedFiles() -> [File]? {
        var files = [File]()
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
            let recordedFiles = urls.filter { $0.pathExtension == "caf" }
            for url in recordedFiles {
                let duration = try AVAudioPlayer(contentsOf: url).duration
                files.append(File(url: url, duration: duration))
            }
            
            return files
        } catch {
            print("Failed to load recorded files: \(error)")
            return nil
        }
    }
}
