//
//  RewriteTool.swift
//
//
//  Created by Iggy Drougge on 2023-10-16.
//

import ArgumentParser
import SwiftSyntax
import SwiftParser
import Foundation

@main
struct RewriteTool: ParsableCommand {
    @Argument var files: [String] = []
    
    mutating func run() throws {
        for file in files {
            let resource = URL(filePath: file)
            let contents = try String(contentsOf: resource)
            let sources = Parser.parse(source: contents)
            let converted = RewriteImageLiteral().visit(sources)
            try converted.description.write(to: resource, atomically: true, encoding: .utf8)
        }
    }
}

class RewriteImageLiteral: SyntaxRewriter {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self)
        else {
            return super.visit(node)
        }
        switch calledExpression.baseName.tokenKind {
        case .identifier("UIImage"): return rewriteUIKitImage(node)
        case .identifier("Image"): return rewriteSwiftUIImage(node)
        case _: return super.visit(node)
        }
    }
    
    // Since `UIImage(named:)` returns an optional, and `UIImage(resource:)` does not, we need to remove the trailing question mark.
    override func visit(_ node: OptionalChainingExprSyntax) -> ExprSyntax {
        guard let expression = node.expression.as(FunctionCallExprSyntax.self),
              let calledExpression = expression.calledExpression.as(DeclReferenceExprSyntax.self),
              case .identifier("UIImage") = calledExpression.baseName.tokenKind
        else {
            return super.visit(node)
        }
        return rewriteUIKitImage(expression)
    }
    
    // Since `UIImage(named:)` returns an optional, and `UIImage(resource:)` does not, we need to remove force unwrap exclamation marks.
    override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
        guard let expression = node.expression.as(FunctionCallExprSyntax.self),
              let calledExpression = expression.calledExpression.as(DeclReferenceExprSyntax.self),
              case .identifier("UIImage") = calledExpression.baseName.tokenKind
        else {
            return super.visit(node)
        }
        return rewriteUIKitImage(expression)
    }
    
    private func rewriteUIKitImage(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let argument = node.arguments.first,
              argument.label?.text == "named",
              let stringLiteralExpression = argument.expression.as(StringLiteralExprSyntax.self),
              let value = stringLiteralExpression.representedLiteralValue, // String interpolation is not allowed.
              !value.isEmpty
        else {
            return super.visit(node)
        }
        
        var node = node
        
        let resourceName = normaliseLiteralName(value)
        
        let expression = MemberAccessExprSyntax(
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(resourceName))
        )
        
        let newArgument = LabeledExprSyntax(
            label: .identifier("resource"),
            colon: .colonToken(trailingTrivia: .space),
            expression: expression
        )
        
        node.arguments = LabeledExprListSyntax([newArgument])
        
        return super.visit(node)
    }
    
    private func rewriteSwiftUIImage(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard let calledExpression = node.calledExpression.as(DeclReferenceExprSyntax.self),
              case .identifier("Image") = calledExpression.baseName.tokenKind,
              let argument = node.arguments.first,
              argument.label == .none,
              let stringLiteralExpression = argument.expression.as(StringLiteralExprSyntax.self),
              let value = stringLiteralExpression.representedLiteralValue, // String interpolation is not allowed.
              !value.isEmpty
        else { return super.visit(node) }
        
        var node = node
        
        let resourceName = normaliseLiteralName(value)
        
        let expression = MemberAccessExprSyntax(
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(resourceName))
        )
        
        let newArgument = LabeledExprSyntax(
            label: .none,
            colon: .none,
            expression: expression
        )
        
        node.arguments = LabeledExprListSyntax([newArgument])
        
        return super.visit(node)
    }
}

private let separators = CharacterSet(charactersIn: " _-")

private func normaliseLiteralName(_ name: String) -> String {
    let (path, name) = extractPathComponents(from: name)
    
    let components = name.components(separatedBy: separators)
    
    guard let head = components.first.map(lowercaseFirst)
    else { return String() }
    
    let tail = components
        .dropFirst()
        .map(uppercaseFirst)
        .joined()
    
    var resourceName = head + tail
    
    if resourceName.hasSuffix("Image") || resourceName.hasSuffix("Color") {
        resourceName.removeLast(5)
    }
    
    if resourceName.first!.isNumber, resourceName.first!.isASCII {
        resourceName = "_" + resourceName
    }
    
    return path + resourceName
}

private func extractPathComponents(from name: String) -> (path: String, name: String) {
    // If literal contains a slash, it maps to a child type of `ImageResource`:
    // "Images/abc_def" → ".Images.abcDef"
    var pathComponents = name.components(separatedBy: "/")
    let name = pathComponents.last ?? name
    pathComponents = pathComponents.dropLast().map(uppercaseFirst(in:))
    if !pathComponents.isEmpty {
        pathComponents.append("") // Add empty portion for trailing dot when joining.
    }
    let path = pathComponents.joined(separator: ".")
    
    return (path, name)
}

private func lowercaseFirst(in string: some StringProtocol) -> any StringProtocol {
    // If first letter is lower-case or non-alphabetic, return string as is.
    guard let first = string.first,
          first.isUppercase
    else { return string }
    // If the entire string is uppercase, just lowercase it all.
    if string.allSatisfy(\.isUppercase) {
        return string.lowercased()
    }
    // Split string where lower case begins.
    let tail = string.drop(while: \.isUppercase)
    // If only initial letter is uppercase, lower case it and return. "Abc" → "abc"
    if string.index(after: string.startIndex) == tail.startIndex {
        return first.lowercased() + string.dropFirst()
    }
    // If tail is not empty, string consists of a sequence of uppercase characters
    // followed by one or several lowercase characters. Lowercase all but the last
    // uppercase character, concatenating it with the lowercase ones. "ABcd" → "aBcd"
    if tail.startIndex != string.endIndex {
        return string[..<tail.startIndex].dropLast().lowercased() + string[..<tail.startIndex].suffix(1) + tail
    }
    // Otherwise, just lowercase initial letter.
    return first.lowercased() + string.dropFirst()
}

private func uppercaseFirst(in string: some StringProtocol) -> String {
    guard let first = string.first else { return String() }
    return first.uppercased() + string.dropFirst()
}
