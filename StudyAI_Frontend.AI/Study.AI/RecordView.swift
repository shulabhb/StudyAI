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

    @State private var noteTitle = ""

    // Error alert state
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    @State private var isSummarizing = false
    @State private var hasRecordedContent = false
    @State private var showCustomSummarizeUI = false

    @State private var progressText = "Summarizing..."

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
                
                // Character counter
                if hasRecordedContent && !transcript.isEmpty {
                    HStack {
                        Spacer()
                        Text("\(transcript.count) characters")
                            .font(.caption)
                            .foregroundColor(transcript.count < 300 ? .orange : (transcript.count > 5000 ? .red : .green))
                            .padding(.horizontal)
                    }
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
                HStack(spacing: 20) {
                    // Record Button
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
                    
                    // Summarize Button
                    Button(action: {
                        if hasRecordedContent && !transcript.isEmpty {
                            let charCount = transcript.count
                            if charCount < 300 {
                                showErrorAlert(message: "Not enough characters. Please record at least 300 characters.")
                                return
                            }
                            showCustomSummarizeUI = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(hasRecordedContent && !transcript.isEmpty ? AppColors.accent : AppColors.card.opacity(0.5))
                                .frame(width: 72, height: 72)
                                .shadow(color: hasRecordedContent && !transcript.isEmpty ? AppColors.accent.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
                                .overlay(
                                    Circle()
                                        .stroke(hasRecordedContent && !transcript.isEmpty ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                                )
                            Image(systemName: "text.bubble")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(!hasRecordedContent || transcript.isEmpty)
                }
                .padding(.bottom, 36)
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
        .onAppear { requestPermissions() }
        .overlay(
            Group {
                if showCustomSummarizeUI {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                            .onTapGesture {
                                showCustomSummarizeUI = false
                            }
                        
                        VStack(spacing: 24) {
                            // Header
                            HStack {
                                Text("Summarize Voice Note")
                                    .font(.title2.weight(.semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: { showCustomSummarizeUI = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Character count info
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundColor(AppColors.accent)
                                Text("\(transcript.count) characters recorded")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            
                            // Title input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Note Title")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                TextField("Enter a title for your note...", text: $noteTitle)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 0)
                            }
                            
                            // Action buttons
                            HStack(spacing: 16) {
                                Button(action: {
                                    resetRecording()
                                    showCustomSummarizeUI = false
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Reset")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    if !noteTitle.isEmpty {
                                        isSummarizing = true
                                        saveAndSummarizeNote()
                                        showCustomSummarizeUI = false
                                    }
                                }) {
                                    HStack {
                                        if isSummarizing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "checkmark.circle")
                                        }
                                        Text(isSummarizing ? "Processing..." : "Save & Summarize")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(noteTitle.isEmpty ? Color.gray : AppColors.accent)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(noteTitle.isEmpty || isSummarizing)
                            }
                        }
                        .padding(24)
                        .background(AppColors.card)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 20)
                    }
                }
                
                if isSummarizing {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    Text(progressText)
                        .font(.title2.bold())
                        .foregroundColor(AppColors.accent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
        hasRecordedContent = true
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
        progressText = "Reading note..."
        NoteService.createNoteViaBackend(name: noteTitle, content: transcript, summaryType: "summary", source: "voice") { result in
            DispatchQueue.main.async {
                progressText = "Summarizing..."
                // Simulate staged progress
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    progressText = "Preparing summary..."
                }
                isSummarizing = false
                switch result {
                case .success(let summaryId):
                    hasRecordedContent = false
                    transcript = "Tap the mic and start speaking..."
                    appState.newSummaryId = summaryId
                    appState.selectedTab = .summaries
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func resetRecording() {
        isRecording = false
        isPaused = false
        duration = 0
        hasRecordedContent = false
        transcript = "Tap the mic and start speaking..."
        audioLevel = 0.4
    }

    private func showErrorAlert(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
