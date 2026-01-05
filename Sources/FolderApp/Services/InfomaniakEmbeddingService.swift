//
//  InfomaniakEmbeddingService.swift
//  Folder
//
//  Service for generating embeddings using Infomaniak API
//

import Foundation

/// Errors that can occur during embedding generation
enum EmbeddingError: Error, LocalizedError {
    case invalidCredentials
    case invalidResponse
    case apiError(String)
    case networkError
    case rateLimitExceeded

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid API credentials"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API error: \(message)"
        case .networkError:
            return "Network error"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        }
    }
}

/// Service for generating embeddings via Infomaniak API
class InfomaniakEmbeddingService {
    static let shared = InfomaniakEmbeddingService()

    private init() {}

    private let model = "mini_lm_l12_v2"
    private let baseURL = "https://api.infomaniak.com/1/ai"

    // MARK: - Request/Response Models

    private struct EmbeddingRequest: Codable {
        let input: String
        let model: String
    }

    private struct EmbeddingResponse: Codable {
        let data: [EmbeddingData]

        struct EmbeddingData: Codable {
            let embedding: [Float]
            let index: Int
        }
    }

    // MARK: - Public Methods

    /// Generate embedding for a single text
    func generateEmbedding(
        text: String,
        apiToken: String,
        productId: String
    ) async throws -> [Float] {
        let request = try buildRequest(text: text, apiToken: apiToken, productId: productId)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmbeddingError.networkError
        }

        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            throw EmbeddingError.rateLimitExceeded
        }

        // Handle other errors
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw EmbeddingError.apiError("Status \(httpResponse.statusCode): \(errorMessage)")
        }

        // Parse response
        let decoder = JSONDecoder()
        guard let embeddingResponse = try? decoder.decode(EmbeddingResponse.self, from: data),
              let firstEmbedding = embeddingResponse.data.first?.embedding else {
            throw EmbeddingError.invalidResponse
        }

        return firstEmbedding
    }

    /// Generate embeddings for multiple texts with concurrency control
    func generateEmbeddings(
        texts: [String],
        apiToken: String,
        productId: String,
        maxConcurrent: Int = 5
    ) async throws -> [[Float]] {
        var embeddings: [[Float]] = Array(repeating: [], count: texts.count)
        var currentIndex = 0
        var errors: [Error] = []

        // Process in batches
        while currentIndex < texts.count {
            let batchSize = min(maxConcurrent, texts.count - currentIndex)
            let batch = Array(texts[currentIndex..<(currentIndex + batchSize)])

            // Process batch concurrently
            await withTaskGroup(of: (Int, Result<[Float], Error>).self) { group in
                for (offset, text) in batch.enumerated() {
                    let index = currentIndex + offset
                    group.addTask {
                        do {
                            // Add small delay to avoid overwhelming the API
                            try await Task.sleep(nanoseconds: UInt64(offset) * 200_000_000) // 200ms * offset
                            let embedding = try await self.generateEmbedding(
                                text: text,
                                apiToken: apiToken,
                                productId: productId
                            )
                            return (index, .success(embedding))
                        } catch {
                            return (index, .failure(error))
                        }
                    }
                }

                for await result in group {
                    let (index, embeddingResult) = result
                    switch embeddingResult {
                    case .success(let embedding):
                        embeddings[index] = embedding
                    case .failure(let error):
                        errors.append(error)
                    }
                }
            }

            currentIndex += batchSize
        }

        // If we have errors, throw the first one
        if let firstError = errors.first {
            throw firstError
        }

        return embeddings
    }

    /// Generate embedding with retry logic for rate limiting
    func generateEmbeddingWithRetry(
        text: String,
        apiToken: String,
        productId: String,
        maxRetries: Int = 3
    ) async throws -> [Float] {
        var lastError: Error?
        var delay: UInt64 = 1_000_000_000 // 1 second

        for attempt in 0..<maxRetries {
            do {
                return try await generateEmbedding(text: text, apiToken: apiToken, productId: productId)
            } catch EmbeddingError.rateLimitExceeded {
                lastError = EmbeddingError.rateLimitExceeded
                if attempt < maxRetries - 1 {
                    // Exponential backoff: 1s, 2s, 4s
                    try await Task.sleep(nanoseconds: delay)
                    delay *= 2
                }
            } catch {
                throw error
            }
        }

        throw lastError ?? EmbeddingError.rateLimitExceeded
    }

    // MARK: - Private Methods

    private func buildRequest(
        text: String,
        apiToken: String,
        productId: String
    ) throws -> URLRequest {
        let urlString = "\(baseURL)/\(productId)/openai/v1/embeddings"
        guard let url = URL(string: urlString) else {
            throw EmbeddingError.invalidCredentials
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = EmbeddingRequest(input: text, model: model)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        return request
    }
}
