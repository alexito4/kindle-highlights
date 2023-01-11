import CustomDump
@testable import kindle_highlights
import XCTest

final class ParsingTests: XCTestCase {
    // MARK: Book and Author line

    func testBookAndAuthors() throws {
        let expected = Book(
            title: "Tress of the Emerald Sea",
            author: "Brandon Sanderson"
        )

        // Test with and without newlines to ensure this specific parser does works independently of others.
        do {
            let raw = "Tress of the Emerald Sea (Brandon Sanderson)"
            var input = raw[...]
            let output = try BookTitleAndAuthorParser().parse(&input)
            XCTAssertNoDifference(output, expected)
            XCTAssertNoDifference(input, "")
        }
        do {
            let raw = """
            Tress of the Emerald Sea (Brandon Sanderson)

            """
            var input = raw[...]
            let output = try BookTitleAndAuthorParser().parse(&input)
            XCTAssertNoDifference(output, expected)
            XCTAssertEqual(input, "\n")
        }
    }

    func testBookAndAuthorDoubleParenthesis() throws {
        let expected = Book(
            title: "The Final Empire: 1 (MISTBORN)",
            author: "Sanderson, Brandon"
        )

        // Test with and without newlines to ensure this specific parser does works independently of others.
        do {
            let raw = "The Final Empire: 1 (MISTBORN) (Sanderson, Brandon)"
            var input = raw[...]
            let output = try BookTitleAndAuthorParser().parse(&input)
            XCTAssertNoDifference(output, expected)
            XCTAssertNoDifference(input, "")
        }
        do {
            let raw = """
            The Final Empire: 1 (MISTBORN) (Sanderson, Brandon)

            """
            var input = raw[...]
            let output = try BookTitleAndAuthorParser().parse(&input)
            XCTAssertNoDifference(output, expected)
            XCTAssertNoDifference(input, "\n")
        }
    }

    // MARK: Metadata

    func testMetadata_Highlight_Page_LocationStartEnd() throws {
        let raw = """
        - Your Highlight on page 266 | location 4071-4072 | Added on Thursday, 19 April 2018 10:44:34

        content
        """
        var input = raw[...]
        let output = try MetadataParser().parse(&input)
        XCTAssertNoDifference(output, Metadata(
            page: 266,
            location: Location(start: 4071, end: 4072),
            date: metadataDateFormatter.date(from: "Thursday, 19 April 2018 10:44:34")!
        ))
        XCTAssertNoDifference(input, "\n\ncontent")
    }

    func testMetadata_Highlight_NoPage_LocationStartEnd() throws {
        let raw = """
        - Your Highlight at location 153-154 | Added on Sunday, 23 September 2018 22:48:46

        content
        """
        var input = raw[...]
        let output = try MetadataParser().parse(&input)
        XCTAssertNoDifference(output, Metadata(
            page: nil,
            location: Location(start: 153, end: 154),
            date: metadataDateFormatter.date(from: "Sunday, 23 September 2018 22:48:46")!
        ))
        XCTAssertNoDifference(input, "\n\ncontent")
    }

    func testMetadata_Note_Page_LocationStart() throws {
        let raw = """
        - Your Note on page 307 | location 4965 | Added on Monday, 7 September 2020 15:42:39

        content
        """
        var input = raw[...]
        let output = try MetadataParser().parse(&input)
        XCTAssertNoDifference(output, Metadata(
            page: 307,
            location: Location(start: 4965, end: nil),
            date: metadataDateFormatter.date(from: "Monday, 7 September 2020 15:42:39")!
        ))
        XCTAssertNoDifference(input, "\n\ncontent")
    }

    // MARK: - Content

    func testContent() throws {
        let raw = """
        A Shardblade did not cut living flesh; it severed the soul itself.
        ==========
        The Lost Metal: A Mistborn Novel (Sanderson, Brandon)
        """
        var input = raw[...]
        let output = try ContentParser().parse(&input)
        XCTAssertNoDifference(output, "A Shardblade did not cut living flesh; it severed the soul itself.")
        XCTAssertNoDifference(input, "==========\nThe Lost Metal: A Mistborn Novel (Sanderson, Brandon)")
    }

    // MARK: - Full Highlight

    func testFull_Highlight_Page_LocationStartEnd() throws {
        let raw = """
        El nombre del viento (Patrick Rothfuss)
        - Your Highlight on page 266 | location 4071-4072 | Added on Thursday, 19 April 2018 10:44:34

        la boca del estómago. Era una sensación parecida a la que tienes cuando alguien te mira la
        ==========
        The Lost Metal: A Mistborn Novel (Sanderson, Brandon)
        """
        var input = raw[...]
        let output = try HighlightParser().parse(&input)
        XCTAssertNoDifference(output, .init(
            book: .init(
                title: "El nombre del viento",
                author: "Patrick Rothfuss"
            ),
            metadata: .init(
                page: 266,
                location: .init(start: 4071, end: 4072),
                date: metadataDateFormatter.date(from: "Thursday, 19 April 2018 10:44:34")!
            ),
            text: """
            la boca del estómago. Era una sensación parecida a la que tienes cuando alguien te mira la
            """
        ))
        XCTAssertNoDifference(input, "==========\nThe Lost Metal: A Mistborn Novel (Sanderson, Brandon)")
    }

    func testFull_Highlight_NoPage_LocationStartEnd() throws {
        let raw = """
        Artemis: A gripping, high-concept thriller from the bestselling author of The Martian (Weir, Andy)
        - Your Highlight at location 153-154 | Added on Sunday, 23 September 2018 22:48:46

        The stores don’t bother to list prices. If you have to ask, you can’t afford it.
        ==========
        The Lost Metal: A Mistborn Novel (Sanderson, Brandon)
        """
        var input = raw[...]
        let output = try HighlightParser().parse(&input)
        XCTAssertNoDifference(output, .init(
            book: .init(
                title: "Artemis: A gripping, high-concept thriller from the bestselling author of The Martian",
                author: "Weir, Andy"
            ),
            metadata: .init(
                page: nil,
                location: .init(start: 153, end: 154),
                date: metadataDateFormatter.date(from: "Sunday, 23 September 2018 22:48:46")!
            ),
            text: """
            The stores don’t bother to list prices. If you have to ask, you can’t afford it.
            """
        ))
        XCTAssertNoDifference(input, "==========\nThe Lost Metal: A Mistborn Novel (Sanderson, Brandon)")
    }

    func testFull_BookWithParenthesis() throws {
        let raw = """
        The Final Empire: 1 (MISTBORN) (Sanderson, Brandon)
        - Your Highlight on page 307 | location 4964-4966 | Added on Monday, 7 September 2020 15:42:17

        “Women are like … thunderstorms. They’re beautiful to look at, and sometimes they’re nice to listen to—but most of the time they’re just plain inconvenient.”
        ==========
        The Lost Metal: A Mistborn Novel (Sanderson, Brandon)
        """
        var input = raw[...]
        let output = try HighlightParser().parse(&input)
        XCTAssertNoDifference(output, .init(
            book: .init(
                title: "The Final Empire: 1 (MISTBORN)",
                author: "Sanderson, Brandon"
            ),
            metadata: .init(
                page: 307,
                location: .init(start: 4964, end: 4966),
                date: metadataDateFormatter.date(from: "Monday, 7 September 2020 15:42:17")!
            ),
            text: """
            “Women are like … thunderstorms. They’re beautiful to look at, and sometimes they’re nice to listen to—but most of the time they’re just plain inconvenient.”
            """
        ))
        XCTAssertNoDifference(input, "==========\nThe Lost Metal: A Mistborn Novel (Sanderson, Brandon)")
    }

    // MARK: - My Clippings File, multiple highlights

    func testMultiple() throws {
        let raw = """
        Oathbringer (Brandon Sanderson)
        - Your Highlight on page 1043 | location 15980-15981 | Added on Sunday, 1 May 2022 12:18:38

        Listener gemhearts were not gaudy or ostentatious, like those of greatshells. Clouded white, almost the color of bone, they were beautiful, intimate things.
        ==========
        Tress of the Emerald Sea (Brandon Sanderson)
        - Your Highlight on page 363 | location 5552-5552 | Added on Sunday, 8 January 2023 13:02:45

        they stayed together. The two of them had both been changed by their journeys—but in complementary ways.
        ==========
        """
        var input = raw[...]
        let output = try MyClippingsParser().parse(&input)
        XCTAssertNoDifference(output, [
            .init(
                book: .init(
                    title: "Oathbringer",
                    author: "Brandon Sanderson"
                ),
                metadata: .init(
                    page: 1043,
                    location: .init(start: 15980, end: 15981),
                    date: metadataDateFormatter.date(from: "Sunday, 1 May 2022 12:18:38")!
                ),
                text: """
                Listener gemhearts were not gaudy or ostentatious, like those of greatshells. Clouded white, almost the color of bone, they were beautiful, intimate things.
                """
            ),
            .init(
                book: .init(
                    title: "Tress of the Emerald Sea",
                    author: "Brandon Sanderson"
                ),
                metadata: .init(
                    page: 363,
                    location: .init(start: 5552, end: 5552),
                    date: metadataDateFormatter.date(from: "Sunday, 8 January 2023 13:02:45")!
                ),
                text: """
                they stayed together. The two of them had both been changed by their journeys—but in complementary ways.
                """
            ),
        ])
        XCTAssertNoDifference(input, "")
    }
}
