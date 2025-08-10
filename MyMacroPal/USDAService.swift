import Foundation

private func loadAPIKey() -> String {
    // Try to load from .env file in main bundle
    guard let envURL = Bundle.main.url(forResource: ".env", withExtension: nil),
          let envString = try? String(contentsOf: envURL) else {
        fatalError("Could not find .env file in bundle.")
    }
    for line in envString.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("USDA_API_KEY=") {
            let key = trimmed.replacingOccurrences(of: "USDA_API_KEY=", with: "")
            if !key.isEmpty {
                return key
            }
        }
    }
    fatalError("USDA_API_KEY not found in .env file.")
}

actor USDAService {
    private let apiKey: String = loadAPIKey()
    private let baseURL: String = "https://api.nal.usda.gov/fdc/v1"

    func searchFoods(query: String, pageSize: Int = 25) async throws -> [USDAFood] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { 
            return [] 
        }
        
        let urlString = "\(baseURL)/foods/search?query=\(encodedQuery)&pageSize=\(pageSize)&api_key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let result = try decoder.decode(USDAFoodSearchResult.self, from: data)
        return result.foods
    }

    func getFoodDetails(fdcId: Int) async throws -> USDAFood {
        let urlString = "\(baseURL)/food/\(fdcId)?api_key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(USDAFood.self, from: data)
    }
}
