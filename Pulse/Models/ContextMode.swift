import Foundation

enum ContextMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case all
    case work
    case personal

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "Все"
        case .work: "Работа"
        case .personal: "Жизнь"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "circle.grid.2x2.fill"
        case .work: "briefcase.fill"
        case .personal: "leaf.fill"
        }
    }

    func includes(_ context: ContextMode) -> Bool {
        self == .all || context == self
    }
}

