import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var expressionTextField: UITextField!
    
    @IBAction func evaluate(sender: UIButton) {
        evaluator.define("$0", string: valueTextField.text!)
        let result = evaluator.eval(expressionTextField.text!)
        print(result)
    }
    
    private var evaluator: TEEvaluator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        evaluator = TEEvaluator()
        evaluator.define("equal", lambda: equal)
        evaluator.define("or", lambda: or)
        evaluator.define("not", lambda: not)
        
        valueTextField.text = "haha"
        expressionTextField.text = "((or (equal A) (equal B) (equal C)) $0)"
    }
    
    func equal(evaluator: TEEvaluator, operands: [TEObject]) -> TEObject {
        if operands.count == 1 {
            let compareTo = operands[0].rawString
            return .Lambda({ (e, args) -> TEObject in
                if args.count == 1 {
                    return args[0].rawString == compareTo ? TEObject.trueObject : TEObject.falseObject
                }
                
                e.error = "equal: invalid operand"
                return .Null
            })
        }
        
        evaluator.error = "equal: invalid operand"
        return .Null
    }
    
    func or(evaluator: TEEvaluator, operands: [TEObject]) -> TEObject {
        var functions: [TEObject.LambdaFunc] = []
        
        for op in operands {
            if let f = op.lambda {
                functions.append(f)
            }
            else {
                evaluator.error = "or: requires lambda"
                return .Null
            }
        }
        
        return .Lambda({ (e, args) -> TEObject in
            for f in functions {
                if let compareResult = f(evaluator: e, operands: args).boolean {
                    if compareResult {
                        return TEObject.trueObject
                    }
                }
                else {
                    break
                }
            }
            
            return TEObject.falseObject
        })
    }
    
    func not(evaluator: TEEvaluator, operands: [TEObject]) -> TEObject {
        if operands.count == 1 {
            if let f = operands[0].lambda {
                return .Lambda({ (e, args) -> TEObject in
                    if let result = f(evaluator: e, operands: args).boolean {
                        return TEObject.booleanObject(!result)
                    }
                    else {
                        e.error = "not: invalid operand"
                        return .Null
                    }
                })
            }
        }
        
        evaluator.error = "not: invalid operands"
        return .Null
    }
}
