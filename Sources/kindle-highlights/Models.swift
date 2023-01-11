import Foundation

struct Highlight: Equatable {
    let book: Book
    let metadata: Metadata
    let text: String
}

struct Book: Equatable {
    let title: String
    let author: String
}

struct Metadata: Equatable {
    let page: Page?
    let location: Location
    let date: Date
}

@dynamicMemberLookup
struct Page: Equatable {
    let number: Int

    subscript<T>(dynamicMember keyPath: KeyPath<Int, T>) -> T {
        number[keyPath: keyPath]
    }
}

extension Page: ExpressibleByIntegerLiteral {
    init(integerLiteral value: IntegerLiteralType) {
        self.init(number: value)
    }
}

struct Location: Equatable {
    let start: Int
    let end: Int?
}
