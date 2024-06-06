//
//  ContentView.swift
//  AudioRecorderAbhishekSaralaya
//
//  Created by Abhishek Saralaya on 06/06/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = AudioRecorder()
    @State private var selectedTab = "One"
    private var screenWidth = UIScreen.main.bounds.width
    private var screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack() {
                Text("\(Int(recorder.recordingDuration.hmsFrom().1), specifier: "%i") : \(Int(recorder.recordingDuration.hmsFrom().2), specifier: "%i")")
                    .font(.largeTitle)
                    .padding()
                    .navigationTitle("Record Audio")
                
                HStack {
                    if recorder.recordingState == .recording {
                        Button(action: {
                            recorder.stopRecording()
                        }) {
                            Image(systemName: "stop.circle")
                                .font(.largeTitle)
                                .padding()
                        }
                        Button(action: {
                            recorder.pauseRecording()
                        }) {
                            Image(systemName: "pause.circle")
                                .font(.largeTitle)
                                .padding()
                        }
                    } else if recorder.recordingState == .ready {
                        Button(action: {
                            recorder.startRecording()
                        }) {
                            Image(systemName: "play.circle")
                                .font(.largeTitle)
                                .padding()
                        }
                    } else if recorder.recordingState == .paused {
                        Button(action: {
                            recorder.stopRecording()
                        }) {
                            Image(systemName: "stop.circle")
                                .font(.largeTitle)
                                .padding()
                        }
                        Button(action: {
                            recorder.resumeRecording()
                        }) {
                            Image(systemName: "play.circle")
                                .font(.largeTitle)
                                .padding()
                        }
                    } else if recorder.recordingState == .recorded {
                        if recorder.isPlaying {
                            Button(action: {
                                recorder.stopPlayback()
                            }) {
                                Image(systemName: "pause.circle")
                                    .font(.largeTitle)
                                    .padding()
                            }
                        } else {
                            Button(action: {
                                recorder.startPlayback(url: nil)
                            }) {
                                Image(systemName: "play.circle")
                                    .font(.largeTitle)
                                    .padding()
                            }
                        }
                    } else {
                        Button(action: {
                            recorder.pauseRecording()
                        }) {
                            Image(systemName: "pause.circle")
                                .font(.largeTitle)
                                .padding()
                        }
                    }
                    
                }.onAppear()
                
                // Volume Meter
                WaveformView(samples: recorder.waveformSamples)
                    .frame(height: 100)
                    .padding()
            }
            .tabItem {
                Image(systemName: "mic.fill")
                    .renderingMode(.template)
            }
            .tag(0)
            
            NavigationStack() {
                VStack {
                    // Your existing UI components
                    // Replace this with your UI components for recording and playback
                    if let files = AudioRecorder.loadRecordedFiles() {
                        List(files, id: \.self) { file in
                            HStack {
                                Text(file.url.lastPathComponent)
                                
                                Text("\(Int(file.duration.hmsFrom().1), specifier: "%i") : \(Int(file.duration.hmsFrom().2), specifier: "%i")")
                                    .padding()
                                    .navigationTitle("List Audio")
                            }.onTapGesture {
                                if recorder.isPlaying {
                                    recorder.stopPlayback()
                                } else {
                                    recorder.startPlayback(url: file.url)
                                }
                            }
                        }
                    }
                }
            }
            .tabItem {
                Image(systemName: "list.clipboard")
                    .renderingMode(.template)
            }
            .tag(1)
        }
    }
}

#Preview {
    ContentView()
}

extension Int {
    
    public func hmsFrom() -> (Int, Int, Int) {
        return (self / 3600, (self % 3600) / 60, (self % 3600) % 60)
    }
    
    public func convertDurationToString() -> String {
        var duration = ""
        let (hour, minute, second) = self.hmsFrom()
        if (hour > 0) {
            duration = self.getHour(hour: hour)
        }
        return "\(duration)\(self.getMinute(minute: minute))\(self.getSecond(second: second))"
    }
    
    private func getHour(hour: Int) -> String {
        var duration = "\(hour):"
        if (hour < 10) {
            duration = "0\(hour):"
        }
        return duration
    }
    
    private func getMinute(minute: Int) -> String {
        if (minute == 0) {
            return "00:"
        }

        if (minute < 10) {
            return "0\(minute):"
        }

        return "\(minute):"
    }
    
    private func getSecond(second: Int) -> String {
        if (second == 0){
            return "00"
        }

        if (second < 10) {
            return "0\(second)"
        }
        return "\(second)"
    }
}


extension TimeInterval {
    func hmsFrom() -> (Int, Int, Int) {
        return (Int(self) / 3600, (Int(self) % 3600) / 60, (Int(self) % 3600) % 60)
    }
}
