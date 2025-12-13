import Foundation
import NaturalLanguage
import ArgumentParser
import SQLite
import Hummingbird
import HTTPTypes

// MARK: - Embedding Service (Apple NLContextualEmbedding)

actor EmbeddingService {
    private var embedding: NLContextualEmbedding?

    func ensureLoaded() async throws {
        if embedding == nil {
            // Get embedding model for English
            guard let model = NLContextualEmbedding(language: .english) else {
                throw BrainError.embeddingModelNotAvailable
            }

            // Check if assets are available, request download if needed
            if !model.hasAvailableAssets {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    model.requestAssets { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }

            try model.load()
            embedding = model
        }
    }

    func embed(text: String) async throws -> [Float] {
        try await ensureLoaded()
        guard let embedding = embedding else {
            throw BrainError.embeddingModelNotAvailable
        }

        let result = try embedding.embeddingResult(for: text, language: .english)

        // Get the embedding vector for the entire text
        var vectors: [[Float]] = []
        result.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { vector, range in
            vectors.append(vector.map { Float($0) })
            return true
        }

        // Average all token vectors to get sentence embedding
        guard !vectors.isEmpty else {
            throw BrainError.embeddingFailed
        }

        let dimension = vectors[0].count
        var averaged = [Float](repeating: 0, count: dimension)
        for vector in vectors {
            for i in 0..<dimension {
                averaged[i] += vector[i]
            }
        }
        for i in 0..<dimension {
            averaged[i] /= Float(vectors.count)
        }

        return averaged
    }

    var dimension: Int {
        get async throws {
            try await ensureLoaded()
            return Int(embedding?.dimension ?? 512)
        }
    }
}

// MARK: - Vector Store (SQLite)

actor VectorStore {
    private let db: Connection
    private let cards = Table("cards")

    // Columns
    private let id = SQLite.Expression<String>("id")
    private let imagePath = SQLite.Expression<String>("image_path")
    private let caption = SQLite.Expression<String>("caption")
    private let embedding = SQLite.Expression<Data>("embedding")
    private let x = SQLite.Expression<Double>("x")
    private let y = SQLite.Expression<Double>("y")
    private let timestamp = SQLite.Expression<Int64>("timestamp")

    init(path: String) throws {
        db = try Connection(path)
        try Self.createTableSync(db: db, cards: cards, id: id, imagePath: imagePath, caption: caption, embedding: embedding, x: x, y: y, timestamp: timestamp)
    }

    private static func createTableSync(db: Connection, cards: Table, id: SQLite.Expression<String>, imagePath: SQLite.Expression<String>, caption: SQLite.Expression<String>, embedding: SQLite.Expression<Data>, x: SQLite.Expression<Double>, y: SQLite.Expression<Double>, timestamp: SQLite.Expression<Int64>) throws {
        try db.run(cards.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(imagePath)
            t.column(caption)
            t.column(embedding)
            t.column(x)
            t.column(y)
            t.column(timestamp)
        })
    }

    func insert(card: Card) throws {
        let embeddingData = card.embedding.withUnsafeBufferPointer { Data(buffer: $0) }
        try db.run(cards.insert(
            id <- card.id,
            imagePath <- card.imagePath,
            caption <- card.caption,
            embedding <- embeddingData,
            x <- card.x,
            y <- card.y,
            timestamp <- card.timestamp
        ))
    }

    func update(card: Card) throws {
        let embeddingData = card.embedding.withUnsafeBufferPointer { Data(buffer: $0) }
        let row = cards.filter(id == card.id)
        try db.run(row.update(
            imagePath <- card.imagePath,
            caption <- card.caption,
            embedding <- embeddingData,
            x <- card.x,
            y <- card.y
        ))
    }

    func delete(cardId: String) throws {
        let row = cards.filter(id == cardId)
        try db.run(row.delete())
    }

    func getAll() throws -> [Card] {
        var result: [Card] = []
        for row in try db.prepare(cards) {
            let embeddingData = row[embedding]
            let embeddingArray = embeddingData.withUnsafeBytes {
                Array(UnsafeBufferPointer<Float>(
                    start: $0.baseAddress?.assumingMemoryBound(to: Float.self),
                    count: embeddingData.count / MemoryLayout<Float>.size
                ))
            }
            result.append(Card(
                id: row[id],
                imagePath: row[imagePath],
                caption: row[caption],
                embedding: embeddingArray,
                x: row[x],
                y: row[y],
                timestamp: row[timestamp]
            ))
        }
        return result
    }

    func search(query: [Float], limit: Int = 10) throws -> [Card] {
        let all = try getAll()

        // Compute cosine similarity for each card
        var scored: [(Card, Float)] = []
        for card in all {
            let similarity = cosineSimilarity(query, card.embedding)
            scored.append((card, similarity))
        }

        // Sort by similarity descending
        scored.sort { $0.1 > $1.1 }

        return Array(scored.prefix(limit).map { $0.0 })
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }

        var dot: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        for i in 0..<a.count {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }

        let denom = sqrt(normA) * sqrt(normB)
        return denom > 0 ? dot / denom : 0
    }
}

// MARK: - Models

struct Card: Codable, Sendable {
    let id: String
    let imagePath: String
    let caption: String
    let embedding: [Float]
    let x: Double
    let y: Double
    let timestamp: Int64
}

struct CardInput: Codable {
    let id: String
    let imagePath: String
    let caption: String
    let x: Double
    let y: Double
}

struct SearchQuery: Codable {
    let query: String
    let limit: Int?
}

struct CardResponse: Codable {
    let id: String
    let imagePath: String
    let caption: String
    let x: Double
    let y: Double
    let timestamp: Int64
    let similarity: Float?
}

enum BrainError: Error, LocalizedError {
    case embeddingModelNotAvailable
    case embeddingFailed
    case cardNotFound

    var errorDescription: String? {
        switch self {
        case .embeddingModelNotAvailable:
            return "NLContextualEmbedding model not available"
        case .embeddingFailed:
            return "Failed to generate embedding"
        case .cardNotFound:
            return "Card not found"
        }
    }
}

// MARK: - Cosine Similarity Helper

func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count else { return 0 }
    var dot: Float = 0
    var normA: Float = 0
    var normB: Float = 0
    for i in 0..<a.count {
        dot += a[i] * b[i]
        normA += a[i] * a[i]
        normB += b[i] * b[i]
    }
    let denom = sqrt(normA) * sqrt(normB)
    return denom > 0 ? dot / denom : 0
}

// MARK: - CORS Middleware

struct CORSMiddleware<Context: RequestContext>: RouterMiddleware {
    func handle(_ request: Request, context: Context, next: (Request, Context) async throws -> Response) async throws -> Response {
        // Handle preflight OPTIONS requests
        if request.method == .options {
            return Response(
                status: .noContent,
                headers: [
                    HTTPField.Name("Access-Control-Allow-Origin")!: "*",
                    HTTPField.Name("Access-Control-Allow-Methods")!: "GET, POST, DELETE, OPTIONS",
                    HTTPField.Name("Access-Control-Allow-Headers")!: "Content-Type"
                ]
            )
        }

        // Add CORS headers to all responses
        var response = try await next(request, context)
        response.headers[HTTPField.Name("Access-Control-Allow-Origin")!] = "*"
        return response
    }
}

// MARK: - CLI

@main
struct ContextCaptureBrain: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Context Capture Brain - Local vector store with Apple Intelligence",
        subcommands: [Serve.self, Embed.self, Search.self],
        defaultSubcommand: Serve.self
    )
}

struct Serve: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Start the HTTP server")

    @Option(name: .shortAndLong, help: "Port to listen on")
    var port: Int = 8770

    @Option(name: .shortAndLong, help: "Path to SQLite database")
    var database: String = "~/.context-capture/brain.db"

    func run() async throws {
        let dbPath = NSString(string: database).expandingTildeInPath
        let dbDir = (dbPath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(atPath: dbDir, withIntermediateDirectories: true)

        print("Starting Context Capture Brain...")
        print("Database: \(dbPath)")
        print("Port: \(port)")

        let embeddingService = EmbeddingService()
        let vectorStore = try VectorStore(path: dbPath)

        // Pre-load embedding model
        print("Loading embedding model...")
        let dimension = try await embeddingService.dimension
        print("Embedding dimension: \(dimension)")

        // Build router with state
        let router = Router()

        // CORS middleware
        router.add(middleware: CORSMiddleware())

        // Health check
        router.get("/health") { _, _ -> String in
            return "OK"
        }

        // Get all cards
        router.get("/cards") { _, _ -> Response in
            let cards = try await vectorStore.getAll()
            let response = cards.map { CardResponse(
                id: $0.id,
                imagePath: $0.imagePath,
                caption: $0.caption,
                x: $0.x,
                y: $0.y,
                timestamp: $0.timestamp,
                similarity: nil
            )}
            let data = try JSONEncoder().encode(response)
            return Response(
                status: .ok,
                headers: [.contentType: "application/json", .accessControlAllowOrigin: "*"],
                body: .init(byteBuffer: ByteBuffer(data: data))
            )
        }

        // Add card
        router.post("/cards") { request, context -> Response in
            let decoder = JSONDecoder()
            let body = try await request.body.collect(upTo: 1024 * 1024)
            let input = try decoder.decode(CardInput.self, from: body)

            let embedding = try await embeddingService.embed(text: input.caption)
            let card = Card(
                id: input.id,
                imagePath: input.imagePath,
                caption: input.caption,
                embedding: embedding,
                x: input.x,
                y: input.y,
                timestamp: Int64(Date().timeIntervalSince1970 * 1000)
            )
            try await vectorStore.insert(card: card)

            let responseData = try JSONEncoder().encode(CardResponse(
                id: card.id,
                imagePath: card.imagePath,
                caption: card.caption,
                x: card.x,
                y: card.y,
                timestamp: card.timestamp,
                similarity: nil
            ))
            return Response(
                status: .created,
                headers: [.contentType: "application/json", .accessControlAllowOrigin: "*"],
                body: .init(byteBuffer: ByteBuffer(data: responseData))
            )
        }

        // Delete card
        router.delete("/cards/{id}") { request, context -> Response in
            guard let cardId = context.parameters.get("id") else {
                return Response(status: .badRequest)
            }
            try await vectorStore.delete(cardId: cardId)
            return Response(status: .noContent, headers: [.accessControlAllowOrigin: "*"])
        }

        // Search
        router.post("/search") { request, context -> Response in
            let decoder = JSONDecoder()
            let body = try await request.body.collect(upTo: 1024 * 1024)
            let query = try decoder.decode(SearchQuery.self, from: body)

            let embedding = try await embeddingService.embed(text: query.query)
            let results = try await vectorStore.search(query: embedding, limit: query.limit ?? 10)

            let response = results.map { card in
                let similarity = cosineSimilarity(embedding, card.embedding)
                return CardResponse(
                    id: card.id,
                    imagePath: card.imagePath,
                    caption: card.caption,
                    x: card.x,
                    y: card.y,
                    timestamp: card.timestamp,
                    similarity: similarity
                )
            }
            let data = try JSONEncoder().encode(response)
            return Response(
                status: .ok,
                headers: [.contentType: "application/json", .accessControlAllowOrigin: "*"],
                body: .init(byteBuffer: ByteBuffer(data: data))
            )
        }

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: port))
        )

        print("Server running at http://127.0.0.1:\(port)")
        print("Endpoints:")
        print("  GET  /health       - Health check")
        print("  GET  /cards        - List all cards")
        print("  POST /cards        - Add a card")
        print("  DELETE /cards/{id} - Delete a card")
        print("  POST /search       - Semantic search")

        try await app.runService()
    }
}

struct Embed: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Generate embedding for text")

    @Argument(help: "Text to embed")
    var text: String

    func run() async throws {
        let service = EmbeddingService()
        print("Loading embedding model...")
        let embedding = try await service.embed(text: text)
        print("Dimension: \(embedding.count)")
        print("First 10 values: \(Array(embedding.prefix(10)))")
    }
}

struct Search: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Search cards by query")

    @Argument(help: "Search query")
    var query: String

    @Option(name: .shortAndLong, help: "Path to SQLite database")
    var database: String = "~/.context-capture/brain.db"

    @Option(name: .shortAndLong, help: "Number of results")
    var limit: Int = 5

    func run() async throws {
        let dbPath = NSString(string: database).expandingTildeInPath
        let embeddingService = EmbeddingService()
        let vectorStore = try VectorStore(path: dbPath)

        print("Loading embedding model...")
        let queryEmbedding = try await embeddingService.embed(text: query)
        let results = try await vectorStore.search(query: queryEmbedding, limit: limit)

        print("\nResults for: \"\(query)\"")
        print("---")
        for (i, card) in results.enumerated() {
            let similarity = cosineSimilarity(queryEmbedding, card.embedding)
            print("\(i + 1). [\(String(format: "%.2f", similarity))] \(card.caption)")
        }
    }
}
