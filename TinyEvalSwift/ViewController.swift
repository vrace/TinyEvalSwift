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
        
        evaluator.define("print", lambda: printObject)
        evaluator.define("options", lambda: options)
        
        valueTextField.text = "haha"
        expressionTextField.text = "(options $0 OVERAGE SHORTAGE EVEN_EXCHANGE)"
    }
    
    private func printObject(evaluator: TEEvaluator, operands: [TEObject]) -> TEObject {
        operands.forEach {
            print($0)
        }
        
        return .Null
    }
    
    private func options(evaluator: TEEvaluator, operands: [TEObject]) -> TEObject {
        if !operands.isEmpty {
            if case .RawString(let value) = operands[0] {
                for candidate in operands[1 ..< operands.count] {
                    if case .RawString(let c) = candidate where c == value {
                        return .RawString("#true")
                    }
                }
                
                return .RawString("\(value) is not in the option list.")
            }
        }
        
        return .RawString("Invalid args")
    }
}
