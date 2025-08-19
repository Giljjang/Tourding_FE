//
//  RecentSearchViewModel.swift
//  Tourding_FE
//
//  Created by 유재혁 on 8/17/25.
//
import Foundation
import Combine

final class RecentSearchViewModel: ObservableObject {
    @Published private(set) var items: [String] = []
    private let key = "recent_search_terms"
    private let maxCount: Int

    init(maxCount: Int = 40) {
        self.maxCount = maxCount
        load()
    }

    func add(_ term: String) {
        let t = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        // 중복 제거 + 최신 맨 앞
        items.removeAll { $0.caseInsensitiveCompare(t) == .orderedSame }
        items.insert(t, at: 0)
        // 최대 40개 유지 → 초과분은 오래된 순으로 삭제
        if items.count > maxCount { items.removeLast(items.count - maxCount) }
        save()
    }

    func remove(_ term: String) {
        items.removeAll { $0 == term }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() {
        items = (UserDefaults.standard.array(forKey: key) as? [String]) ?? []
    }

    private func save() {
        UserDefaults.standard.set(items, forKey: key)
    }
}
