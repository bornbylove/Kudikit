// xcode: set sdk=iOS

import AVFoundation

/// A helper class to request camera permissions, configure an AVCaptureSession safely (including simulator scenarios),
/// and provide a testable abstraction via the CaptureSession protocol.
protocol CaptureSession: NSObjectProtocol {
  var sessionPreset: AVCaptureSession.Preset { get set }
  var inputs: [AVCaptureInput] { get }
  var outputs: [AVCaptureOutput] { get }
  var automaticallyConfiguresApplicationAudioSession: Bool { get set }
  var isRunning: Bool { get }

  func beginConfiguration()
  func commitConfiguration()
  func startRunning()
  func stopRunning()
  func canSetSessionPreset(_ preset: AVCaptureSession.Preset) -> Bool
  func addInputWithNoConnections(_ input: CaptureInput)
  func addOutputWithNoConnections(_ output: AVCaptureOutput)
  func addConnection(_ connection: AVCaptureConnection)
  func addInput(_ input: CaptureInput)
  func addOutput(_ output: AVCaptureOutput)
  func removeInput(_ input: CaptureInput)
  func removeOutput(_ output: AVCaptureOutput)
  func canAddInput(_ input: CaptureInput) -> Bool
  func canAddOutput(_ output: AVCaptureOutput) -> Bool
  func canAddConnection(_ connection: AVCaptureConnection) -> Bool
}

final class CaptureInput: NSObject {
  let avInput: AVCaptureInput
  init(deviceInput: AVCaptureDeviceInput) { self.avInput = deviceInput }
}

extension AVCaptureSession: CaptureSession {
  var sessionPreset: AVCaptureSession.Preset {
    get { self.sessionPreset }
    set { self.sessionPreset = newValue }
  }

  var inputs: [AVCaptureInput] {
    self.inputs
  }

  var outputs: [AVCaptureOutput] {
    self.outputs
  }

  var automaticallyConfiguresApplicationAudioSession: Bool {
    get { self.automaticallyConfiguresApplicationAudioSession }
    set { self.automaticallyConfiguresApplicationAudioSession = newValue }
  }

  var isRunning: Bool {
    self.isRunning
  }

  func beginConfiguration() {
    self.beginConfiguration()
  }

  func commitConfiguration() {
    self.commitConfiguration()
  }

  func startRunning() {
    self.startRunning()
  }

  func stopRunning() {
    self.stopRunning()
  }

  func canSetSessionPreset(_ preset: AVCaptureSession.Preset) -> Bool {
    self.canSetSessionPreset(preset)
  }

  func addInputWithNoConnections(_ input: CaptureInput) {
    self.addInputWithNoConnections(input.avInput)
  }

  func addOutputWithNoConnections(_ output: AVCaptureOutput) {
    self.addOutputWithNoConnections(output)
  }

  func addConnection(_ connection: AVCaptureConnection) {
    self.addConnection(connection)
  }

  func addInput(_ input: CaptureInput) {
    self.addInput(input.avInput)
  }

  func addOutput(_ output: AVCaptureOutput) {
    self.addOutput(output)
  }

  func removeInput(_ input: CaptureInput) {
    self.removeInput(input.avInput)
  }

  func removeOutput(_ output: AVCaptureOutput) {
    self.removeOutput(output)
  }

  func canAddInput(_ input: CaptureInput) -> Bool {
    self.canAddInput(input.avInput)
  }

  func canAddOutput(_ output: AVCaptureOutput) -> Bool {
    self.canAddOutput(output)
  }

  func canAddConnection(_ connection: AVCaptureConnection) -> Bool {
    self.canAddConnection(connection)
  }
}

final class CameraManager {
  enum CameraManagerError: Error {
    case noCameraDeviceAvailable
    case cannotCreateInput
    case cannotAddInput
    case cannotSetPreset
  }

  private let session: CaptureSession
  private var videoInput: CaptureInput?
  private var videoOutput: AVCaptureVideoDataOutput?

  init(session: CaptureSession = AVCaptureSession()) {
    self.session = session
    self.session.automaticallyConfiguresApplicationAudioSession = false
    print("[CameraManager] Initialized. Auto-configure audio session: \(self.session.automaticallyConfiguresApplicationAudioSession)")
  }

  @MainActor
  func requestCameraAccess() async -> Bool {
    print("[CameraManager] Requesting camera access… (Main thread: \(Thread.isMainThread))")
    return await withCheckedContinuation { continuation in
      AVCaptureDevice.requestAccess(for: .video) { granted in
        print("[CameraManager] Camera access granted: \(granted)")
        continuation.resume(returning: granted)
      }
    }
  }

  func configureForFrontCamera(preset: AVCaptureSession.Preset = .high) throws {
    print("[CameraManager] configureForFrontCamera called with preset: \(preset). Main thread: \(Thread.isMainThread)")

    // Discover the front wide angle camera if available
    let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    print("[CameraManager] Front camera device: \(String(describing: device))")

    guard let device else {
      print("[CameraManager] No front camera device available (simulator may not provide one).")
      throw CameraManagerError.noCameraDeviceAvailable
    }

    do {
      let deviceInput = try AVCaptureDeviceInput(device: device)
      print("[CameraManager] Created AVCaptureDeviceInput for device: \(device)")
      let captureInput = CaptureInput(deviceInput: deviceInput)

      session.beginConfiguration()
      print("[CameraManager] Session beginConfiguration")

      // Set preset if possible
      if session.canSetSessionPreset(preset) {
        session.sessionPreset = preset
        print("[CameraManager] Session preset set to \(preset)")
      } else {
        print("[CameraManager] Cannot set preset: \(preset)")
        session.commitConfiguration()
        print("[CameraManager] Session commitConfiguration (after failing to set preset)")
        throw CameraManagerError.cannotSetPreset
      }

      // Remove existing inputs
      if !session.inputs.isEmpty {
        print("[CameraManager] Removing \(session.inputs.count) existing input(s)")
      }
      for input in session.inputs {
        if let deviceInput = input as? AVCaptureDeviceInput {
          let wrapped = CaptureInput(deviceInput: deviceInput)
          session.removeInput(wrapped)
        }
      }

      guard session.canAddInput(captureInput) else {
        print("[CameraManager] Cannot add video input to session")
        session.commitConfiguration()
        print("[CameraManager] Session commitConfiguration (after cannotAddInput)")
        throw CameraManagerError.cannotAddInput
      }

      session.addInput(captureInput)
      print("[CameraManager] Added video input")
      self.videoInput = captureInput

      // Optionally configure a video data output to ensure the pipeline is valid
      let videoOutput = AVCaptureVideoDataOutput()
      if session.canAddOutput(videoOutput) {
        session.addOutput(videoOutput)
        self.videoOutput = videoOutput
        print("[CameraManager] Added video output")
      } else {
        print("[CameraManager] Could not add video output; continuing without it.")
      }

      session.commitConfiguration()
      print("[CameraManager] Session commitConfiguration")
      print("[CameraManager] Session configured for front camera with preset \(preset)")
    } catch {
      print("[CameraManager] Error creating device input: \(error)")
      throw CameraManagerError.cannotCreateInput
    }
  }

  func start() {
    guard !session.isRunning else {
      print("[CameraManager] start() skipped — session already running")
      return
    }
    session.startRunning()
    print("[CameraManager] Session started")
  }

  func stop() {
    guard session.isRunning else {
      print("[CameraManager] stop() skipped — session not running")
      return
    }
    session.stopRunning()
    print("[CameraManager] Session stopped")
  }
}
