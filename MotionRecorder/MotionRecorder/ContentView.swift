import SwiftUI

struct ContentView: View {
    @State private var viewModel: MotionRecorderViewModel
    @State private var exportFileURL: URL?
    @State private var showingShareSheet = false
    @State private var showingError = false

    init(viewModel: MotionRecorderViewModel? = nil) {
        if let viewModel = viewModel {
            _viewModel = State(initialValue: viewModel)
        } else {
            do {
                _viewModel = State(initialValue: try MotionRecorderViewModel())
            } catch {
                fatalError("Failed to initialize ViewModel: \(error)")
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                statusSection
                Divider()
                dataInfoSection
                Spacer()
                actionButtons
            }
            .padding()
            .navigationTitle("Motion Recorder")
            .task {
                await viewModel.initialize()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showingError = newValue != nil
            }
        }
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(viewModel.isRecording ? Color.red : Color.gray)
                    .frame(width: 12, height: 12)

                Text(viewModel.isRecording ? "Recording" : "Stopped")
                    .font(.headline)
                    .foregroundStyle(viewModel.isRecording ? .red : .secondary)
            }

            if viewModel.recordCount > 0 {
                Text("\(viewModel.recordCount) data points recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var dataInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recording Data")
                .font(.headline)
                .padding(.bottom, 4)

            DataInfoRow(
                label: "First Recording",
                value: viewModel.firstRecordingTime?.formatted() ?? "N/A"
            )

            DataInfoRow(
                label: "Last Recording",
                value: viewModel.lastRecordingTime?.formatted() ?? "N/A"
            )

            DataInfoRow(
                label: "Last Export",
                value: viewModel.lastExportTime?.formatted() ?? "Never"
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                        .font(.title2)

                    Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isRecording ? Color.red : Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }

            exportButton
        }
    }

    private var exportButton: some View {
        Button(action: {
            Task {
                do {
                    let url = try await viewModel.exportData()
                    exportFileURL = url
                    showingShareSheet = true
                    await viewModel.refreshStats()
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)

                Text("Export to CSV")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundStyle(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.recordCount == 0)
        .opacity(viewModel.recordCount == 0 ? 0.5 : 1.0)
    }
}

#Preview {
    ContentView()
}
