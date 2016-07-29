import Foundation

enum TEObject {
    typealias LambdaFunc = (evaluator: TEEvaluator, operands: [TEObject]) -> TEObject
    
    case Null
    case Lambda(LambdaFunc)
    case RawString(String)
    
    var rawString: String? {
        if case .RawString(let str) = self {
            return str
        }
        
        return nil
    }
    
    var boolean: Bool? {
        let str = rawString
        
        if str == "#true" {
            return true
        }
        else if str == "#false" {
            return false
        }
        
        return nil
    }
    
    var lambda: LambdaFunc? {
        if case .Lambda(let f) = self {
            return f
        }
        
        return nil
    }
    
    static var trueObject: TEObject {
        return .RawString("#true")
    }
    
    static var falseObject: TEObject {
        return .RawString("#false")
    }
    
    static func booleanObject(value: Bool) -> TEObject {
        return value ? trueObject : falseObject
    }
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
    
    enum StackObject {
        case FunctionCall
        case Argument(TEObject)
    }
    
    private func eval(tokenizer: TETokenizer) -> TEObject {
        var stack: [StackObject] = []
        
        while (error == nil && tokenizer.token != nil) {
            if tokenizer.token == "(" {
                stack.append(.FunctionCall)
            }
            else if tokenizer.token == ")" {
                var args: [TEObject] = []
                while (!stack.isEmpty) {
                    if case .Argument(let arg) = stack.removeLast() {
                        args.append(arg)
                    }
                    else {
                        stack.append(.Argument(apply(Array(args.reverse()))))
                        break
                    }
                }
            }
            else {
                stack.append(.Argument(apply(tokenizer.token!)))
            }
            
            tokenizer.next()
        }
        
        if !stack.isEmpty {
            if case .Argument(let result) = stack[0] {
                return result
            }
            else {
                error = "unexpected evaluation result"
            }
        }
        
        return .Null
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
