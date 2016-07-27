import Foundation

enum TEObject {
    case Null
    case Lambda((evaluator: TEEvaluator, operands: [TEObject]) -> TEObject)
    case RawString(String)
}

class TETokenizer {
    private var expression: String
    private(set) var token: String?
    
    init(expression: String) {
        self.expression = expression
        next()
    }
    
    func next() {
        token = nil
        expression = expression.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if !expression.isEmpty {
            if expression.hasPrefix("(") || expression.hasPrefix(")") {
                token = String(expression.removeAtIndex(expression.startIndex))
            }
            else {
                let end = expression.findAny([" ", ")"])
                token = expression.substringWithRange(expression.startIndex ..< end)
                expression = expression.substringFromIndex(end)
            }
        }
    }
}

private extension String {
    func findAny(candidates: [Character]) -> String.Index {
        for pair in self.characters.enumerate() {
            if candidates.contains(pair.element) {
                return self.startIndex.advancedBy(pair.index)
            }
        }
        
        return self.endIndex
    }
}

class TEEvaluator {
    private var symbols: [String: TEObject]
    var error: String?
    
    init() {
        symbols = [:]
    }
    
    func define(name: String, symbol: TEObject) {
        symbols[name] = symbol
    }
    
    func define(name: String, lambda: (evaluator: TEEvaluator, operands: [TEObject]) -> TEObject) {
        define(name, symbol: .Lambda(lambda))
    }
    
    func define(name: String, string: String) {
        define(name, symbol: .RawString(string))
    }
    
    func eval(expression: String) -> TEObject {
        error = nil
        return eval(TETokenizer(expression: expression))
    }
    
    private func eval(tokenizer: TETokenizer) -> TEObject {
        var result: TEObject = .Null
        
        if let token = tokenizer.token {
            if token == "(" {
                var args: [TEObject] = []
                
                tokenizer.next()
                
                while error == nil && tokenizer.token != nil && tokenizer.token != ")" {
                    args.append(eval(tokenizer))
                }
                
                if tokenizer.token != ")" {
                    if error == nil {
                        error = "unexpected end of expression"
                    }
                }
                else {
                    if error == nil && !args.isEmpty {
                        result = apply(args)
                    }
                }
            }
            else {
                result = apply(token)
            }
        }
        
        tokenizer.next()
        
        return result
    }
    
    private func apply(exp: String) -> TEObject {
        if let symbol = symbols[exp] {
            return symbol
        }
        else {
            return .RawString(exp)
        }
    }
    
    private func apply(args: [TEObject]) -> TEObject {
        if !args.isEmpty {
            if case .Lambda(let lambda) = args[0] {
                return lambda(evaluator: self, operands: Array<TEObject>(args[1 ..< args.count]))
            }
            else {
                error = "invalid operator"
            }
        }
        
        return .Null
    }
}
