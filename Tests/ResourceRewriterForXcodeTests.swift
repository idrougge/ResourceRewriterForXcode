//
//  ResourceRewriterForXcodeTests.swift
//  
//
//  Created by Iggy Drougge on 2023-10-17.
//

import XCTest
import SwiftParser
@testable import ResourceRewriterForXcode

final class ResourceRewriterForXcodeTests: XCTestCase {

    let rewriter = RewriteImageLiteral()

    func testUIKitImage() throws {
        let input = Parser.parse(source: #"UIImage(named: "abc")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"UIImage(resource: .abc)"#
        )
    }
    
    func testUIKitImageWithExtraArguments() throws {
        let input = Parser.parse(source: #"UIImage(named: "abc", in: .module, with: nil)"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"UIImage(resource: .abc)"#
        )
    }
    
    func testUIKitImageWithOptionalChaining() throws {
        let input = Parser.parse(source: #"UIImage(named: "abc")?.cgImage"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"UIImage(resource: .abc).cgImage"#,
            "Trailing question mark should be removed from chained expression."
        )
    }
    
    func testUIKitImageWithForceUnwrap() throws {
        let input = Parser.parse(source: #"UIImage(named: "abc")!.cgImage"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"UIImage(resource: .abc).cgImage"#,
            "Trailing question mark should be removed from chained expression."
        )
    }
    
    func testSwiftUIImage() throws {
        let input = Parser.parse(source: #"Image("abc")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.abc)"#
        )
    }
    
    func testLiteralWithTrailingImageInName() throws {
        let input = Parser.parse(source: #"Image("abcImage")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.abc)"#,
            "'Image' should be stripped from end of image resource names."
        )
    }
    
    func testLiteralWithSpacesInName() throws {
        let input = Parser.parse(source: #"Image("abc def")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.abcDef)"#,
            "Image names with spaces should be joined into camel cased identifiers."
        )
    }
    
    func testLiteralWithUnderscoresInName() throws {
        let input = Parser.parse(source: #"Image("abc_def")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.abcDef)"#,
            "Image names with underscores should be joined into camel cased identifiers."
        )
    }
    
    func testLiteralWithHyphensInName() throws {
        let input = Parser.parse(source: #"Image("abc-def")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.abcDef)"#,
            "Image names with hyphens should be joined into camel cased identifiers."
        )
    }
    
    func testLiteralWithSlashesInName() throws {
        let input = Parser.parse(source: #"Image("abc/Def")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.Abc.def)"#,
            "Image names with slashes should translate into chained accessors."
        )
    }
    
    func testLiteralWithEmptyName() throws {
        let input = Parser.parse(source: #"Image("")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image("")"#,
            "Empty image names should not be altered as they cannot map to any resource."
        )
    }
    
    func testLiteralWithCapitalLeadingLetter() throws {
        let input = Parser.parse(source: #"Image("AbcImage")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.abc)"#,
            "Leading capital letter should be lowercased."
        )
    }
    
    func testLiteralWithCapitalLeadingLettersAndUnderscore() throws {
        let input = Parser.parse(source: #"Image("TEMP_abc_TEMP")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.tempAbcTEMP)"#,
            "Image names with uppercase leading letters separated by non-letters should have the leading run of characters lowercased."
        )
    }
    
    func testLiteralWithCapitalLeadingLettersAndSpaces() throws {
        let input = Parser.parse(source: #"Image("ÅÄÖ abc TEMP")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.åäöAbcTEMP)"#,
            "Image names with uppercase leading letters separated by non-letters should have the leading run of characters lowercased."
        )
    }
    
    func testLiteralWithCapitalLeadingLetters() throws {
        let input = Parser.parse(source: #"Image("TEMPabcTEMP")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(.temPabcTEMP)"#,
            "Image names with uppercase leading letters followed by lowercase letters should be lowercased, with the uppercase one anterior to the first lowercase one preserving upper case."
        )
    }
    
    func testLiteralWithLeadingNumberInName() throws {
        let input = Parser.parse(source: #"Image("123 abc")"#)
        let output = rewriter.visit(input)
        XCTAssertEqual(
            output.description,
            #"Image(._123Abc)"#,
            "Image names with leading number should be preceded by underscore."
        )
    }
}
