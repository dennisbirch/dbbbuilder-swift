//
//  ViewController.swift
//  KeyGenerator
//
//  Created by Dennis Birch on 1/29/19.
//  Copyright © 2019 Dennis Birch. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextViewDelegate {

    @IBOutlet private weak var inputTextView: NSTextView!
    @IBOutlet private weak var outputTextView: NSTextView!
    @IBOutlet private weak var classNameField: NSTextField!
    @IBOutlet private weak var typePopup: NSPopUpButton!
    @IBOutlet private weak var generateButton: NSButton!
    @IBOutlet private weak var copyCodeButton: NSButton!

    private enum TypeOption: String {
        case int = "Integer"
        case string = "String"
        case double = "Double"
        case bool = "Bool"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        typePopup.removeAllItems()
        typePopup.addItem(withTitle: TypeOption.int.rawValue)
        typePopup.addItem(withTitle: TypeOption.string.rawValue)
        typePopup.addItem(withTitle: TypeOption.double.rawValue)
        typePopup.addItem(withTitle: TypeOption.bool.rawValue)
        
        updateGenerateButton()
        updateCopyCodeButton()
        inputTextView.delegate = self
        outputTextView.delegate = self
    }
    
    @IBAction func generateKeys(_ sender: NSButton) {
        let input = inputTextView.string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let className = classNameField.stringValue
        
        guard input.isEmpty == false, className.isEmpty == false else {
            print("The property list or class name must be provided!")
            return
        }
        
        outputTextView.string = parseAndGenerate(input, className: className)
    }
    
    @IBAction func copyCode(_ sender: NSButton) {
        let range = outputTextView.selectedRange()
        outputTextView.selectAll(nil)
        outputTextView.copy(nil)
        outputTextView.setSelectedRange(range)
    }
    
    private func parseAndGenerate(_ text: String, className: String) -> String {
        guard let defaultType = typePopup.selectedItem?.title else {
            print("Default type popup's selected item is nil")
            return ""
        }

        guard let typeOption = TypeOption(rawValue: defaultType) else {
            print("Can't create type option")
            return ""
        }
        let storageType = "\(dbbType(forTypeOption: typeOption).name())"
        
        var inputSeparator: String?
        let separators = ["\n", ",", " "]
        for sep in separators {
            if text.contains(sep) {
                inputSeparator = sep
                break
            }
        }
        
        guard let separator = inputSeparator?.first else {
            print("Unable to determine input separator")
            return ""
        }
        
        let rawText = (separator == "\n") ? cleanText(text) : text.split(separator: separator).map{ String($0) }
        
        let keyText = rawText.map{ return "static let \($0) = \"\($0)\"" }
        let varText = rawText.map{ return "@objc var \($0) = \(defaultVarValue(forTypeOption: typeOption))" }
        let mapText = rawText.map{ return "Keys.\($0) : DBBPropertyPersistence(type: \(storageType))" }
        let mapString = mapText.joined(separator: ",\n")
        
        let initMethod =
        """
required init(dbManager: DBBManager) {
super.init(dbManager: dbManager)

let map: [String : DBBPropertyPersistence] = [\(mapString)]

dbManager.addPersistenceMapContents(map, forTableNamed: shortName)
}
"""
        let joinedKeyText = keyText.joined(separator: "\n")
        let joinedVarText = varText.joined(separator: "\n")
        return """
final class \(className): DBBTableObject {
struct Keys {
\(joinedKeyText)
}

\(joinedVarText)

\(initMethod)
}
"""
    }
    
    private func cleanText(_ text: String) -> [String] {
        let isObjectiveCPropertyList = text.contains("@property")
        
        let terms = ["var", "@objc", "weak", "=", "(", ")", ",", "@property", "nonatomic", "@IBOutlet", "weak", "strong", "assign", "copy", "strong", "@", "*", ";"]
        var output = text
        for term in terms {
            output = output.replacingOccurrences(of: term, with: "")
        }
        
        var lines = output.split(separator: "\n").map {
            return String($0)
        }
        
        if isObjectiveCPropertyList {
            return cleanupObjectiveCProperties(lines: lines)
        } else {
            
            let cleanLineArray: [String] = lines.map {
                let line = cleanLine(cleanLine(cleanLine($0, limitCharacter: ":"), limitCharacter: "="), limitCharacter: "\"")
                return line
            }
            
            lines = cleanLineArray
            
            return lines
        }
    }
    
    private func cleanupObjectiveCProperties(lines: [String]) -> [String] {
        let lastWordArray: [String] = lines.compactMap{
            let spaceSeparatedComponents = $0.split(separator: " ")
            if let substring = (spaceSeparatedComponents.last) {
                return String(substring)
            } else {
                return nil
            }
        }
        
        return lastWordArray
    }
    
    private func cleanLine(_ line: String, limitCharacter: String) -> String {
        var output = line
        if let range = output.range(of: limitCharacter) {
            let distance = output.distance(from: output.startIndex, to: range.lowerBound)
            let startIndex = output.startIndex
            let endIndex = output.index(output.startIndex, offsetBy: distance)
            output = String(output[startIndex..<endIndex]).trimmingCharacters(in: CharacterSet.whitespaces)
        }
        
        return output.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    private func dbbType(forTypeOption type: TypeOption) -> DBBGenerationStorageType {
        switch type {
        case .bool:
            return .bool
        case .int:
            return .int
        case .double:
            return .float
        case .string:
            return .string
        }
    }
    
    private func defaultVarValue(forTypeOption type: TypeOption) -> String {
        switch type {
        case .bool:
            return "false"
        case .int:
            return "0"
        case .double:
            return "0.0"
        case .string:
            return "\"\""
        }
    }
    
    private func updateGenerateButton() {
        generateButton.isEnabled = inputTextView.string.isEmpty == false && classNameField.stringValue.isEmpty == false
    }
    
    private func updateCopyCodeButton() {
        copyCodeButton.isEnabled = outputTextView.string.isEmpty == false
    }
    
    override func keyUp(with event: NSEvent) {
        updateGenerateButton()
        updateCopyCodeButton()
    }
    
    override func mouseUp(with event: NSEvent) {
        updateGenerateButton()
        updateCopyCodeButton()
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
        updateCopyCodeButton()
        updateGenerateButton()
    }
    
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertTab(_:)) {
            textView.window?.selectNextKeyView(nil)
            return true
        } else if commandSelector == #selector(insertBacktab(_:)) {
            if textView == outputTextView {
                textView.window?.makeFirstResponder(inputTextView)
            } else {
                // input textView
                textView.window?.makeFirstResponder(classNameField)
            }
            return true
        }
        
        return false
    }
}

