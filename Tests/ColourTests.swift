//
//  ColourTests.swift
//  
//
//  Created by Iggy Drougge on 2024-01-22.
//

import XCTest
import SwiftParser
@testable import ResourceRewriterForXcode

final class ColourTests: XCTestCase {

    let rewriter = RewriteColourLiteral()

    func testUIKitColour() throws {
        let input = Parser.parse(source: #"UIColor(named: "abc")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"UIColor(resource: .abc)"#
        )
    }
    
    func testUIKitColourWithExtraArguments() throws {
        let input = Parser.parse(source: #"UIColor(named: "abc", in: .module, with: nil)"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"UIColor(resource: .abc)"#
        )
    }
    
    func testUIKitColourWithOptionalChaining() throws {
        let input = Parser.parse(source: #"UIColor(named: "abc")?.cgColor"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"UIColor(resource: .abc).cgColor"#,
            "Trailing question mark should be removed from chained expression."
        )
    }
    
    func testUIKitColourWithForceUnwrap() throws {
        let input = Parser.parse(source: #"UIColor(named: "abc")!.cgColor"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"UIColor(resource: .abc).cgColor"#,
            "Trailing question mark should be removed from chained expression."
        )
    }
    
    func testSwiftUIColor() throws {
        let input = Parser.parse(source: #"Color("abc")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.abc)"#
        )
    }
    
    func testLiteralWithTrailingColorInName() throws {
        let input = Parser.parse(source: #"Color("abcColor")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.abc)"#,
            "`Color` should be stripped from end of colour resource names."
        )
    }
    
    func testLiteralWithSpacesInName() throws {
        let input = Parser.parse(source: #"Color("abc def")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.abcDef)"#,
            "Colour names with spaces should be joined into camel cased identifiers."
        )
    }
    
    func testLiteralWithUnderscoresInName() throws {
        let input = Parser.parse(source: #"Color("abc_def")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.abcDef)"#,
            "Colour names with spaces should be joined into camel cased identifiers."
        )
    }
    
    func testLiteralWithHyphensInName() throws {
        let input = Parser.parse(source: #"Color("abc-def")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.abcDef)"#,
            "Colour names with hyphens should be joined into camel cased identifiers."
        )
    }
    
    func testLiteralWithEmptyName() throws {
        let input = Parser.parse(source: #"Color("")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color("")"#,
            "Empty Colour names should not be altered as they cannot map to any resource."
        )
    }
    
    func testLiteralWithCapitalLeadingLetter() throws {
        let input = Parser.parse(source: #"Color("AbcColor")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.abc)"#,
            "Leading capital letter should be lowercased."
        )
    }
    
    func testLiteralWithCapitalLeadingLettersAndUnderscore() throws {
        let input = Parser.parse(source: #"Color("TEMP_abc_TEMP")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.tempAbcTEMP)"#,
            "Colour names with uppercase leading letters separated by non-letters should have the leading run of characters lowercased."
        )
    }
    
    func testLiteralWithCapitalLeadingLettersAndSpaces() throws {
        let input = Parser.parse(source: #"Color("ÅÄÖ abc TEMP")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.åäöAbcTEMP)"#,
            "Colour names with uppercase leading letters separated by non-letters should have the leading run of characters lowercased."
        )
    }
    
    func testLiteralWithCapitalLeadingLetters() throws {
        let input = Parser.parse(source: #"Color("TEMPabcTEMP")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(.temPabcTEMP)"#,
            "Colour names with uppercase leading letters followed by lowercase letters should be lowercased, with the uppercase one anterior to the first lowercase one preserving upper case."
        )
    }
    
    func testLiteralWithLeadingNumberInName() throws {
        let input = Parser.parse(source: #"Color("123 abc")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Color(._123Abc)"#,
            "Colour names with leading number should be preceded by underscore."
        )
    }
}
