import Foundation

private func loadAPIKey() -> String? {
    // Prefer Info.plist value if present
    if let key = Bundle.main.object(forInfoDictionaryKey: "USDA_API_KEY") as? String, !key.isEmpty {
        return key
    }
    // Fallback to process environment (useful for previews/tests)
    if let key = ProcessInfo.processInfo.environment["USDA_API_KEY"], !key.isEmpty {
        return key
    }
    return nil
}

enum USDAServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "USDA API key is missing. Add 'USDA_API_KEY' to Info.plist or provide it via environment variable."
        case .invalidURL:
            return "Invalid USDA API URL."
        case .httpError(let statusCode):
            return "USDA API request failed with status code \(statusCode)."
        }
    }
}

actor USDAService {
    private let apiKey: String? = loadAPIKey()
    private let baseURL: String = "https://api.nal.usda.gov/fdc/v1"

    func searchFoods(query: String, pageSize: Int = 25) async throws -> [USDAFood] {
        guard let apiKey else { throw USDAServiceError.missingAPIKey }
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        let urlString = "\(baseURL)/foods/search?query=\(encodedQuery)&pageSize=\(pageSize)"
        guard let url = URL(string: urlString) else {
            throw USDAServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw USDAServiceError.httpError(statusCode: http.statusCode)
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(USDAFoodSearchResult.self, from: data)
        return result.foods
    }

    func getFoodDetails(fdcId: Int) async throws -> USDAFood {
        guard let apiKey else { throw USDAServiceError.missingAPIKey }
        let urlString = "\(baseURL)/food/\(fdcId)"
        guard let url = URL(string: urlString) else {
            throw USDAServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw USDAServiceError.httpError(statusCode: http.statusCode)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(USDAFood.self, from: data)
    }
}
