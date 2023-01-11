import Baggins
import Foundation
import Parsing

/// Parses the Book title and author line
/// Example: Tress of the Emerald Sea (Brandon Sanderson)
/// Example: The Final Empire: 1 (MISTBORN) (Sanderson, Brandon)
struct BookTitleAndAuthorParser: Parser {
    func parse(_ input: inout Substring) throws -> Book {
        var (first, rest): (Substring, [Substring]) = try Parse {
            PrefixUpTo("(")

            Many {
                parenthesisContentParser()
            } separator: {
                Whitespace(.horizontal)
            }
        }.parse(&input)

        guard rest.isEmpty == false else {
            fatalError("Expected at least one text in parenthesis for the author.")
        }
        let author = String(rest.removeLast())
        var title = String(first)
        if rest.isEmpty == false {
            title += rest
                .map { "(\($0))" }
                .joined(separator: " ")
        }
        return Book(
            title: title.trimmingCharacters(in: .whitespaces),
            author: author
        )
    }

    /// (something)
    /// returns: something
    private func parenthesisContentParser() -> some Parser<Substring, Substring> {
        Parse {
            "("
            PrefixUpTo(")")
            ")"
        }
    }
}

/// Pares the metadata line, including page, location and date.
/// Example: - Your Highlight on page 266 | location 4071-4072 | Added on Thursday, 19 April 2018 10:44:34
struct MetadataParser: Parser {
    func parse(_ input: inout Substring) throws -> Metadata {
        try Parse(Metadata.init(page:location:date:)) {
            "- "
            OneOf {
                Parse {
                    pageHighlight()
                    " | "
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
            " | "
            addedDate()
        }
        .parse(&input)
    }

    /// Your Highlight on page 266
    private func pageHighlight() -> some Parser<Substring, Page> {
        Parse(Page.init(number:)) {
            OneOf {
                "Your Highlight on page "
                "Your Note on page "
            }
            Int.parser()
        }
    }

    /// location 4071-4072
    private func locationPart() -> some Parser<Substring, Location> {
        Parse {
            "location "
            locationParser()
        }
    }

    private func locationParser() -> some Parser<Substring, Location> {
        Parse(Location.init(start:end:)) {
            Int.parser()
            Optionally {
                "-"
                Int.parser()
            }
        }
    }

    /// Your Highlight at location 153-154
    private func locationHighlight() -> some Parser<Substring, Location> {
        Parse {
            OneOf {
                "Your Highlight at location "
                "Your Note at location "
            }
            locationParser()
        }
    }

    /// Added on Thursday, 19 April 2018 10:44:34
    private func addedDate() -> some Parser<Substring, Date> {
        Parse {
            "Added on "
            Parsers.prefixUpToNewline
                .map { (str: Substring) in
                    DateFormatter.metadataDateFormatter
                        .date(from: String(str))! // TODO: Use the formatter as a parser directly
                }
        }
    }
}

private extension DateFormatter {
    /// Thursday, 19 April 2018 10:44:34
    static let metadataDateFormatter = DateFormatter().then {
        $0.dateFormat = "EEEE, d MMM yyyy HH:mm:ss"
        $0.locale = Locale(identifier: "en_US")
    }
}

/// Parses the content of a highlight
struct ContentParser: Parser {
    func parse(_ input: inout Substring) throws -> String {
        try Parse {
            PrefixUpTo(MyClippingsParser.highlightSeparator)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        .parse(&input)
    }
}

/// Parses a full highlight, including book title and author, metadata and the content itself
struct HighlightParser: Parser {
    func parse(_ input: inout Substring) throws -> Highlight {
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

    func parse(_ input: inout Substring) throws -> [Highlight] {
        try Many {
            HighlightParser()
        } separator: {
            Self.highlightSeparator
            Whitespace(1, .vertical)
        } terminator: {
            Self.highlightSeparator
            Whitespace()
            End()
        }
        .parse(&input)
    }
}
