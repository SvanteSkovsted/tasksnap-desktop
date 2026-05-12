import Foundation

// MARK: - SupabaseService

final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    // Fill in your Supabase anon key from: Dashboard → Settings → API → Project API keys
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh4cnpxdmFndnBneXFlanZqaWlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3NzAzMjgsImV4cCI6MjA3NTM0NjMyOH0.r7RZzh-giep_LX03qcULD0DeXP1COBElQCy-XLMesDk"
    private let baseURL = "https://hxrzqvagvpgyqejvjiil.supabase.co"

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthSession {
        let url = try makeURL("/auth/v1/token?grant_type=password")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        let (data, response) = try await URLSession.shared.data(for: request)
        try assertSuccess(response: response, data: data)
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    // MARK: - Capture

    /// Returns the task title extracted from the server response, if present.
    func captureTask(audioData: Data) async throws -> String? {
        guard
            let userId = KeychainService.shared.userId,
            let token  = KeychainService.shared.accessToken
        else { throw VocaFlowError.notAuthenticated }

        let url = try makeURL("/functions/v1/capture-task")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let body = CaptureRequest(
            user_id:      userId,
            audio_base64: audioData.base64EncodedString(),
            mime_type:    "audio/m4a"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try assertSuccess(response: response, data: data)

        // Best-effort title extraction — structure varies by server version.
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let title = json["title"] as? String { return title }
            if let task = json["task"] as? [String: Any], let t = task["title"] as? String { return t }
        }
        return nil
    }

    // MARK: - Helpers

    private func makeURL(_ path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else { throw VocaFlowError.badURL }
        return url
    }

    private func assertSuccess(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw VocaFlowError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw VocaFlowError.serverError(http.statusCode, message)
        }
    }
}

// MARK: - Models

struct AuthSession: Decodable {
    let access_token: String
    let user: UserInfo
}

struct UserInfo: Decodable {
    let id: String
}

struct CaptureRequest: Encodable {
    let user_id: String
    let audio_base64: String
    let mime_type: String
}

// MARK: - Errors

enum VocaFlowError: LocalizedError {
    case badURL
    case invalidResponse
    case notAuthenticated
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .badURL:                        return "Invalid URL."
        case .invalidResponse:               return "Unexpected server response."
        case .notAuthenticated:              return "Please sign in first."
        case .serverError(let code, let msg): return "Server error \(code): \(msg)"
        }
    }
}
