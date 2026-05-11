import Foundation
import AVFoundation
import Accelerate
import Combine

// MARK: - AudioRecorder

final class AudioRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var frequencyBands: [Float] = .init(repeating: 0, count: 30)

    private let engine    = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var currentURL: URL?

    // MARK: - Session setup

    func prepareSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)
    }

    // MARK: - Recording

    func startRecording() throws {
        guard !isRecording else { return }
        try prepareSession()

        let inputNode   = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("vf_\(Int(Date().timeIntervalSince1970)).m4a")

        let fileSettings: [String: Any] = [
            AVFormatIDKey:              kAudioFormatMPEG4AAC,
            AVSampleRateKey:            inputFormat.sampleRate,
            AVNumberOfChannelsKey:      1,
            AVEncoderAudioQualityKey:   AVAudioQuality.high.rawValue
        ]
        audioFile  = try AVAudioFile(forWriting: url, settings: fileSettings)
        currentURL = url

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            try? self?.audioFile?.write(from: buffer)
            self?.processFFT(buffer: buffer)
        }

        try engine.start()

        DispatchQueue.main.async { self.isRecording = true }
    }

    /// Returns the recorded file URL. Caller must read the data before the next recording overwrites it.
    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil

        DispatchQueue.main.async {
            self.isRecording = false
            self.frequencyBands = .init(repeating: 0, count: 30)
        }

        return currentURL
    }

    // MARK: - FFT

    private func processFFT(buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount >= 64 else { return }

        let fftSize = 1024
        let n       = min(frameCount, fftSize)
        let log2n   = vDSP_Length(log2(Float(fftSize)))

        // Hann window
        var windowed = [Float](repeating: 0, count: fftSize)
        var window   = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(data, 1, window, 1, &windowed, 1, vDSP_Length(n))

        // FFT
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return }
        defer { vDSP_destroy_fftsetup(setup) }

        var realParts = [Float](repeating: 0, count: fftSize / 2)
        var imagParts = [Float](repeating: 0, count: fftSize / 2)
        realParts.withUnsafeMutableBufferPointer { realBuf in
            imagParts.withUnsafeMutableBufferPointer { imagBuf in
                var cplx = DSPSplitComplex(realp: realBuf.baseAddress!, imagp: imagBuf.baseAddress!)
                windowed.withUnsafeBufferPointer { winBuf in
                    winBuf.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) {
                        vDSP_ctoz($0, 2, &cplx, 1, vDSP_Length(fftSize / 2))
                    }
                }
                vDSP_fft_zrip(setup, &cplx, 1, log2n, FFTDirection(FFT_FORWARD))
                vDSP_zvmags(&cplx, 1, realBuf.baseAddress!, 1, vDSP_Length(fftSize / 2))
            }
        }

        // Scale → dB → normalize
        var scale: Float = 1.0 / Float(fftSize * 2)
        vDSP_vsmul(realParts, 1, &scale, &realParts, 1, vDSP_Length(fftSize / 2))

        var dbMags = [Float](repeating: 0, count: fftSize / 2)
        var ref: Float = 1.0
        vDSP_vdbcon(realParts, 1, &ref, &dbMags, 1, vDSP_Length(fftSize / 2), 0)

        let minDB: Float = -60, maxDB: Float = 0
        let normalized = dbMags.map { max(0, min(1, ($0 - minDB) / (maxDB - minDB))) }

        // Log-spaced bands
        let bandCount   = 30
        let sampleRate  = Float(buffer.format.sampleRate)
        let halfBins    = fftSize / 2
        var bands = [Float](repeating: 0, count: bandCount)

        for i in 0..<bandCount {
            let lo = 40  * pow(22000.0 / 40.0, Float(i)     / Float(bandCount))
            let hi = 40  * pow(22000.0 / 40.0, Float(i + 1) / Float(bandCount))
            let lowBin  = max(0, Int(lo / sampleRate * Float(halfBins * 2)))
            let highBin = min(halfBins - 1, Int(hi / sampleRate * Float(halfBins * 2)))
            guard lowBin <= highBin else { continue }
            var sum: Float = 0
            vDSP_sve(Array(normalized[lowBin...highBin]), 1, &sum, vDSP_Length(highBin - lowBin + 1))
            bands[i] = sum / Float(highBin - lowBin + 1)
        }

        DispatchQueue.main.async {
            self.frequencyBands = bands
        }
    }
}
