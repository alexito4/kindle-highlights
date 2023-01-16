import Baggins
import Foundation
import Parsing

extension Parsers {
    static let prefixUpToNewline = Prefix { !$0.isNewline }
}

extension Parser where Input == Substring {
    /// Parses the given String and prints the output and the pending input.
    func printDebug(_ raw: String) throws -> Output {
        var input = raw[...]
        let output = try parse(&input)
        print("             ")
        print("->\(output)<-")
        print("-]\(input)[-")
        print("             ")
        return output
    }
}

public extension Parser {
    func debug() -> Parsers.Debug<Self> {
        .init(upstream: self)
    }
}

public extension Parsers {
    struct Debug<Upstream: Parser>: Parser {
        let upstream: Upstream

        init(
            upstream: Upstream
        ) {
            self.upstream = upstream
        }

        public func parse(_ input: inout Upstream.Input) throws -> Upstream.Output {
            let output = try upstream.parse(&input)
            print("Output:", output)
            print("Input after:", input)
            return output
        }
    }
}

public extension Parser {
    func tryMap<NewOutput>(
        _ transform: @escaping (Output) throws -> NewOutput
    ) -> Parsers.TryMap<Self, NewOutput> {
        .init(upstream: self, transform: transform)
    }
}

public extension Parsers {
    struct TryMap<Upstream: Parser, NewOutput>: Parser {
        let upstream: Upstream

        let transform: (Upstream.Output) throws -> NewOutput

        init(
            upstream: Upstream,
            transform: @escaping (Upstream.Output) throws -> NewOutput
        ) {
            self.upstream = upstream
            self.transform = transform
        }

        public func parse(_ input: inout Upstream.Input) throws -> NewOutput {
            try transform(try upstream.parse(&input))
        }
    }
}
