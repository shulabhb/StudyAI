import SwiftUI
import AVFoundation
import Speech
import FirebaseAuth
import FirebaseFirestore

struct RecordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @State private var isRecording = false
    @State private var isPaused = false
    @State private var transcript = "Tap the mic and start speaking..."
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var timer: Timer?
    @State private var glowTimer: Timer?
    @State private var duration: TimeInterval = 0
    @State private var request: SFSpeechAudioBufferRecognitionRequest?
    @State private var glowIntensity: Double = 0.4
    @State private var audioLevel: CGFloat = 0.4

    @State private var showSaveOptions = false
    @State private var showTitlePrompt = false
    @State private var noteTitle = ""

    // Error alert state
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    @State private var isSummarizing = false

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🎙 Voice Note")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ScrollView {
                    Text(transcript)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.background)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .scrollContentBackground(.hidden)
                }

                Spacer()

                if isRecording {
                    VStack(spacing: 10) {
                        Text("Recording: \(formatTime(duration))")
                            .font(.subheadline)
                            .foregroundColor(.white)

                        Button(action: {
                            isPaused ? resumeRecording() : pauseRecording()
                        }) {
                            Label(isPaused ? "Resume" : "Pause",
                                  systemImage: isPaused ? "play.fill" : "pause.fill")
                                .padding()
                                .foregroundColor(.primary)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .shadow(radius: 2)
                        }
                    }
                    .padding(.bottom, 150)
                }
            }
            .padding()

            VStack {
                Spacer()
                Button(action: {
                    provideHapticFeedback()
                    isRecording ? stopRecording() : startRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : AppColors.card)
                            .frame(width: 72, height: 72)
                            .scaleEffect(isRecording ? audioLevel : 1.0)
                            .shadow(color: isRecording ? Color.red.opacity(0.4) : Color.white.opacity(0.15), radius: isRecording ? 32 * audioLevel : 8, x: 0, y: 4)
                            .overlay(
                                Circle()
                                    .stroke(isRecording ? Color.white : Color.white.opacity(0.5), lineWidth: 2)
                            )
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 36)
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
        .onAppear { requestPermissions() }
        .alert("Save this note?", isPresented: $showSaveOptions) {
            Button("Save & Summarize") { showTitlePrompt = true }
            Button("Discard", role: .destructive) {
                transcript = "Tap the mic and start speaking..."
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to save this note or discard it?")
        }
        .sheet(isPresented: $showTitlePrompt) {
            VStack(spacing: 20) {
                Text("Name your note")
                    .font(.headline)

                TextField("Enter a title...", text: $noteTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button("Save & Summarize") {
                    isSummarizing = true
                    saveAndSummarizeNote()
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .disabled(isSummarizing)

                Button("Cancel", role: .cancel) {
                    showTitlePrompt = false
                }
            }
            .presentationDetents([.height(250)])
            .padding()
        }
        .overlay(
            Group {
                if isSummarizing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Summarizing...")
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                            .foregroundColor(.white)
                            .padding(32)
                            .background(AppColors.card)
                            .cornerRadius(16)
                    }
                }
            }
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Record Notes")
                    .font(.custom("AvenirNext-UltraLight", size: 22))
                    .foregroundColor(.white)
            }
        }
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus != .authorized {
                    transcript = "Speech recognition not authorized."
                } else {
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        DispatchQueue.main.async {
                            if !granted {
                                transcript = "Microphone permission denied."
                            }
                        }
                    }
                }
            }
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func pauseRecording() {
        isPaused = true
        timer?.invalidate()
        glowTimer?.invalidate()
        audioEngine.pause()
    }

    private func resumeRecording() {
        isPaused = false
        startTimer()
        startGlowTimer()
        try? audioEngine.start()
    }

    private func provideHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func startRecording() {
        isRecording = true
        isPaused = false
        duration = 0
        if transcript == "Tap the mic and start speaking..." {
            transcript = ""
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else {
            transcript = "Failed to create audio request."
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
                let rms = buffer.floatChannelData?.pointee
                let frameLength = Int(buffer.frameLength)
                var sum: Float = 0
                if let rms = rms {
                    for i in 0..<frameLength { sum += rms[i] * rms[i] }
                    let mean = sum / Float(frameLength)
                    let level = CGFloat(min(max(sqrt(mean) * 10, 0.4), 1.5))
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            audioLevel = level
                        }
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
                DispatchQueue.main.async {
                    if let result = result {
                        transcript = result.bestTranscription.formattedString
                    }
                }
            }

            startTimer()
            startGlowTimer()

        } catch {
            transcript = "Recording error: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        isRecording = false
        isPaused = false
        timer?.invalidate()
        glowTimer?.invalidate()
        timer = nil
        glowTimer = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.finish()

        DispatchQueue.main.async { audioLevel = 0.4 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showSaveOptions = true
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            duration += 1
        }
    }

    private func startGlowTimer() {
        glowTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                glowIntensity = 0.4 + Double.random(in: 0.2...0.6)
            }
        }
    }

    private func saveAndSummarizeNote() {
        guard !noteTitle.isEmpty, !transcript.isEmpty else {
            showErrorAlert(message: "Title or transcript is empty.")
            isSummarizing = false
            return
        }
        NoteService.createNoteViaBackend(name: noteTitle, content: transcript, summaryType: "summary", source: "voice") { result in
            DispatchQueue.main.async {
                isSummarizing = false
                switch result {
                case .success(let summaryId):
                    appState.newSummaryId = summaryId
                    appState.selectedTab = .summaries
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func showErrorAlert(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
