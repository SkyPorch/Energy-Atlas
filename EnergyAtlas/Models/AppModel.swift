//
//  AppModel.swift
//  EnergyAtlas
//
//

import SwiftUI
import AVFoundation

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // Controls whether a floating 3-D chart attached to the globe should be visible
    var showChart: Bool = false
    
    // Controls whether the AI analysis panel should be visible
    var showAIPanel: Bool = false
    
    // Controls whether the ambient music is muted
    var isMusicMuted: Bool = false
    
    // MARK: - Audio Cues
    private var enterSoundPlayer: AVAudioPlayer?
    private var leaveSoundPlayer: AVAudioPlayer?
    
    /// Plays the "Enter Energy Atlas" cue (m4a in main bundle).
    func playEnterCue() {
        if enterSoundPlayer == nil {
            if let url = Bundle.main.url(forResource: "Enter Energy Atlas", withExtension: "m4a") {
                enterSoundPlayer = try? AVAudioPlayer(contentsOf: url)
                enterSoundPlayer?.prepareToPlay()
            }
        }
        enterSoundPlayer?.currentTime = 0
        enterSoundPlayer?.play()
    }
    
    /// Plays the "Leave Energy Atlas" cue (m4a in main bundle).
    func playLeaveCue() {
        if leaveSoundPlayer == nil {
            if let url = Bundle.main.url(forResource: "Leave Energy Atlas", withExtension: "m4a") {
                leaveSoundPlayer = try? AVAudioPlayer(contentsOf: url)
                leaveSoundPlayer?.prepareToPlay()
            }
        }
        leaveSoundPlayer?.currentTime = 0
        leaveSoundPlayer?.play()
    }
}
