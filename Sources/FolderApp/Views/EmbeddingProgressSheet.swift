//
//  EmbeddingProgressSheet.swift
//  Folder
//
//  Modal dialog for embedding generation progress
//

import SwiftUI

/// Modal sheet showing embedding generation progress
struct EmbeddingProgressSheet: View {
    @ObservedObject var embeddingManager: EmbeddingManager
    let folderPath: URL
    @Binding var isPresented: Bool

    @State private var filesList: [FileSystemItem] = []
    @State private var isProcessingStarted = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                // Header
                headerView

                // Credentials check
                if !embeddingManager.hasValidCredentials {
                    credentialsWarningView
                }

                // File list or progress
                if !isProcessingStarted {
                    fileListView
                } else {
                    progressView
                }

                // Buttons
                buttonsView
            }
            .padding(24)
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            print("DEBUG: EmbeddingProgressSheet appeared")
            loadFilesList()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Enable Embedding Search")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()
            }

            HStack {
                Text(folderPath.lastPathComponent)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
    }

    // MARK: - Credentials Warning

    private var credentialsWarningView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("Missing API Credentials")
                    .font(.headline)

                Text("Please add INFOMANIAK_API_TOKEN and INFOMANIAK_PRODUCT_ID to your .env file")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - File List

    private var fileListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Found \(filesList.count) embeddable files")
                    .font(.headline)

                Spacer()

                Text("PDF, Markdown")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if filesList.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No embeddable files found")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("This folder contains no PDF or Markdown files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filesList) { file in
                            HStack(spacing: 8) {
                                Image(systemName: file.path.pathExtension.lowercased() == "pdf" ? "doc.fill" : "doc.text.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)

                                Text(file.name)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)

                                Spacer()

                                Text(formatFileSize(file.size))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(minHeight: 250, maxHeight: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Progress View

    private var progressView: some View {
        VStack(spacing: 16) {
            if let progress = embeddingManager.processingProgress {
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Processing...")
                            .font(.headline)

                        Spacer()

                        Text("\(progress.current)/\(progress.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: Double(progress.current), total: Double(progress.total))
                        .progressViewStyle(LinearProgressViewStyle())

                    if !progress.currentFile.isEmpty {
                        Text("Current: \(progress.currentFile)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // Stats
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Success")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(progress.successCount)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Errors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(progress.errors.count)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }

                    Spacer()
                }
                .padding(.top, 8)

                // Error list (if any)
                if !progress.errors.isEmpty && progress.isComplete {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Errors:")
                            .font(.headline)
                            .foregroundColor(.red)

                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(progress.errors, id: \.filename) { error in
                                    HStack(spacing: 8) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(error.filename)
                                                .font(.caption)
                                                .fontWeight(.medium)

                                            Text(error.error)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                        .padding(8)
                        .background(Color.red.opacity(0.05))
                        .cornerRadius(8)
                    }
                }

                Spacer()
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            }
        }
    }

    // MARK: - Buttons

    private var buttonsView: some View {
        HStack(spacing: 12) {
            if isProcessingStarted && embeddingManager.processingProgress?.isComplete == true {
                // Completion message
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    if let progress = embeddingManager.processingProgress {
                        Text("Completed: \(progress.successCount) files embedded")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            } else if isProcessingStarted {
                // Processing
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)

                    Text("Processing...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Cancel") {
                    isPresented = false
                }
            } else {
                // Not started
                Spacer()

                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Start Processing") {
                    startProcessing()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!embeddingManager.hasValidCredentials || filesList.isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func loadFilesList() {
        filesList = embeddingManager.getEmbeddableFiles(in: folderPath)
        print("DEBUG: Loaded \(filesList.count) embeddable files from \(folderPath.path)")
        print("DEBUG: Has credentials: \(embeddingManager.hasValidCredentials)")
    }

    private func startProcessing() {
        isProcessingStarted = true

        Task {
            do {
                try await embeddingManager.enableEmbedding(for: folderPath)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
