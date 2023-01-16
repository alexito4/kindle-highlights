import Baggins
import Foundation
import Parsing

/// Parses the Book title and author line
/// Example: Tress of the Emerald Sea (Brandon Sanderson)
/// Example: The Final Empire: 1 (MISTBORN) (Sanderson, Brandon)
struct BookTitleAndAuthorParser: Parser {
    func parse(_ input: inout Substring.UTF8View) throws -> Book {
        var (first, rest): (Substring.UTF8View, [Substring.UTF8View]) = try Parse {
            PrefixUpTo("(".utf8)

            Many {
                parenthesisContentParser()
            } separator: {
                Whitespace(.horizontal)
            }
        }.parse(&input)

        guard rest.isEmpty == false else {
            fatalError("Expected at least one text in parenthesis for the author.")
        }
        let author = String(rest.removeLast())! // utf8 to string is optional, but i'm not breaking unicode in theory
        var title = String(first)!
        if rest.isEmpty == false {
            title += rest
                .map(String.init)
                .map { "(\($0!))" }
                .joined(separator: " ")
        }
        return Book(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author
        )
    }

    /// (something)
    /// returns: something
    private func parenthesisContentParser() -> some Parser<Substring.UTF8View, Substring.UTF8View> {
        Parse {
            "(".utf8
            PrefixUpTo(")".utf8)
            ")".utf8
        }
    }
}

/// Pares the metadata line, including page, location and date.
/// Example: - Your Highlight on page 266 | location 4071-4072 | Added on Thursday, 19 April 2018 10:44:34
struct MetadataParser: Parser {
    func parse(_ input: inout Substring.UTF8View) throws -> Metadata {
        try Parse(Metadata.init(page:location:date:)) {
            "- ".utf8
            OneOf {
                Parse {
                    pageHighlight()
                    " | ".utf8
                    locationPart()
                }
                .map { page, location -> (Page?, Location) in
                    (page, location)
                }

                locationHighlight()
                    .map { location -> (Page?, Location) in
                        (nil, location)
                    }
            }
            " | ".utf8
            addedDate()
        }
        .parse(&input)
    }

    /// Your Highlight on page 266
    private func pageHighlight() -> some Parser<Substring.UTF8View, Page> {
        Parse(Page.init(number:)) {
            OneOf {
                "Your Highlight on page ".utf8
                "Your Note on page ".utf8
            }
            Int.parser()
        }
    }

    /// location 4071-4072
    private func locationPart() -> some Parser<Substring.UTF8View, Location> {
        Parse {
            "location ".utf8
            locationParser()
        }
    }

    private func locationParser() -> some Parser<Substring.UTF8View, Location> {
        Parse(Location.init(start:end:)) {
            Int.parser()
            Optionally {
                "-".utf8
                Int.parser()
            }
        }
    }

    /// Your Highlight at location 153-154
    private func locationHighlight() -> some Parser<Substring.UTF8View, Location> {
        Parse {
            OneOf {
                "Your Highlight at location ".utf8
                "Your Note at location ".utf8
            }
            locationParser()
        }
    }

    /// Added on Thursday, 19 April 2018 10:44:34
    private func addedDate() -> some Parser<Substring.UTF8View, Date> {
        Parse {
            "Added on ".utf8
            From(.substring) { Parsers.prefixUpToNewline }
                .map { (str: Substring) -> Date in
                    DateFormatter.metadataDateFormatter
                        .date(from: String(str))! // TODO: Use the formatter as a parser directly
                }
        }
    }
}

extension DateFormatter {
    /// Thursday, 19 April 2018 10:44:34
    static let metadataDateFormatter = DateFormatter().then {
        $0.dateFormat = "EEEE, d MMM yyyy HH:mm:ss"
        $0.locale = Locale(identifier: "en_US")
    }
}

/// Parses the content of a highlight
struct ContentParser: Parser {
    func parse(_ input: inout Substring.UTF8View) throws -> String {
        try Parse {
            PrefixUpTo(MyClippingsParser.highlightSeparator.utf8)
                .map { String($0)!.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        .parse(&input)
    }
}

/// Parses a full highlight, including book title and author, metadata and the content itself
struct HighlightParser: Parser {
    func parse(_ input: inout Substring.UTF8View) throws -> Highlight {
        try Parse(Highlight.init(book:metadata:text:)) {
            BookTitleAndAuthorParser()
            Whitespace(.vertical)
            MetadataParser()
            Whitespace(.vertical)
            ContentParser()
        }
        .parse(&input)
    }
}

/// Parses My Clippings File, multiple highlights
struct MyClippingsParser: Parser {
    fileprivate static let highlightSeparator = "=========="

    func parse(_ input: inout Substring.UTF8View) throws -> [Highlight] {
        var i = 0
        return try Many(
            into: [],
            {
                i += 1
                print(i)
                $0.append($1)
            }
        ) {
            HighlightParser()
        } separator: {
            Self.highlightSeparator.utf8
            Whitespace(1, .vertical)
        } terminator: {
            Self.highlightSeparator.utf8
            Whitespace()
            End()
        }
        .parse(&input)
    }
}
