//
//  FixtureLoader.swift
//  Tourding_FE
//

import Foundation

enum FixtureLoader {
    enum LoaderError: LocalizedError {
        case fileNotFound(String)
        case decodeFailed(String, Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let filename):
                return "Fixture not found: \(filename)"
            case .decodeFailed(let filename, let error):
                return "Fixture decode failed (\(filename)): \(error.localizedDescription)"
            }
        }
    }

    static func load<T: Decodable>(
        _ filename: String,
        bundle: Bundle = .main
    ) throws -> T {
        let data = try data(for: filename, bundle: bundle)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LoaderError.decodeFailed(filename, error)
        }
    }

    private static func data(for filename: String, bundle: Bundle) throws -> Data {
        guard let url = fixtureURL(named: filename, bundle: bundle) else {
            throw LoaderError.fileNotFound(filename)
        }
        return try Data(contentsOf: url)
    }

    private static func fixtureURL(named filename: String, bundle: Bundle) -> URL? {
        let resourceName = (filename as NSString).deletingPathExtension
        let fileExtension = (filename as NSString).pathExtension.isEmpty ? "json" : (filename as NSString).pathExtension

        let subdirectories = ["Fixtures", "Resources/Fixtures", nil as String?]
        for subdirectory in subdirectories {
            if let subdirectory,
               let url = bundle.url(
                forResource: resourceName,
                withExtension: fileExtension,
                subdirectory: subdirectory
               ) {
                return url
            }

            if subdirectory == nil,
               let url = bundle.url(forResource: resourceName, withExtension: fileExtension) {
                return url
            }
        }

        return nil
    }
}
