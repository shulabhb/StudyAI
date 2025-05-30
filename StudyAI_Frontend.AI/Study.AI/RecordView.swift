import SwiftUI
import AVFoundation
import Speech
import FirebaseAuth
import FirebaseFirestore

struct RecordView: View {
    @EnvironmentObject var appState: AppState            // ① grab the AppState
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

    @State private var showSaveOptions = false
    @State private var showTitlePrompt = false
    @State private var noteTitle = ""
    @State private var summaryType = "medium"           // ② default to “medium”

    private let summaryOptions = ["short", "medium", "detailed", "academic"]
  

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 16) {
                Text("🎙 Voice Note")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // ─── ③ PICKER ──────────────────────────────────────────────────────
                Picker("Summary Type", selection: $summaryType) {
                    ForEach(summaryOptions, id: \.self) {
                        Text($0.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                ScrollView {
                    Text(transcript)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

                Spacer()

                if isRecording {
                    VStack(spacing: 10) {
                        Text("Recording: \(formatTime(duration))")
                            .font(.subheadline)
                            .foregroundColor(.red)

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

            Button(action: {
                provideHapticFeedback()
                isRecording ? stopRecording() : startRecording()
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .frame(width: 90, height: 90)
                    .foregroundColor(isPaused ? .gray : (isRecording ? .red : .blue))
                    .shadow(color: (isPaused ? .gray : (isRecording ? Color.red : Color.blue))
                                .opacity(glowIntensity),
                            radius: 20)
                    .scaleEffect(isRecording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isRecording)
            }
            .padding(.bottom, 40)
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
                    saveAndSummarizeNote()
                    noteTitle = ""
                    showTitlePrompt = false
                }
                .padding()
                .buttonStyle(.borderedProminent)

                Button("Cancel", role: .cancel) {
                    showTitlePrompt = false
                }
            }
            .presentationDetents([.height(250)])
            .padding()
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
           guard let userID = Auth.auth().currentUser?.uid else {
               print("❌ No logged-in user."); return
           }
           guard let url = URL(string: "http://127.0.0.1:8000/summarize_raw") else {
               print("❌ Invalid backend URL"); return
           }

           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           let boundary = UUID().uuidString
           request.setValue("multipart/form-data; boundary=\(boundary)",
                            forHTTPHeaderField: "Content-Type")

           var body = Data()
           let formFields: [(String, String)] = [
               ("content", transcript),
               ("user_id", userID),
               ("title", noteTitle),
               ("summary_type", summaryType)
           ]
           for (key, value) in formFields {
               body.append("--\(boundary)\r\n")
               body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
               body.append("\(value)\r\n")
           }
           body.append("--\(boundary)--\r\n")
           request.httpBody = body

           URLSession.shared.dataTask(with: request) { data, _, error in
               if let error = error {
                   print("❌ Network error: \(error)"); return
               }
               guard let data = data,
                     let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                     let summary = json["summary"] as? String else {
                   print("❌ Failed to decode response"); return
               }

               let db = Firestore.firestore()
               let noteData: [String: Any] = [
                   "user_id": userID,
                   "title": noteTitle,
                   "content": transcript,
                   "summary": summary,
                   "source": "voice",
                   "createdAt": Timestamp()
               ]

               db.collection("users")
                 .document(userID)
                 .collection("notes")
                 .addDocument(data: noteData) { err in
                   if let err = err {
                       print("❌ Firestore error: \(err.localizedDescription)")
                   } else {
                       // ─── ④ AFTER SAVE: jump to Summaries tab ─────────────
                       DispatchQueue.main.async {
                           appState.selectedTab = .summaries
                           presentationMode.wrappedValue.dismiss()
                       }
                   }
               }
           }.resume()
       }
   }
