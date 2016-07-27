import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var expressionTextField: UITextField!
    
    @IBAction func evaluate(sender: UIButton) {
        let result = evaluator.eval(expressionTextField.text!)
        print(result)
    }
    
    private var evaluator: TEEvaluator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        evaluator = TEEvaluator()
        
        evaluator.define("print", lambda: printObject)
    }
    
    private func printObject(evaluator: TEEvaluator, operands: [TEObject]) -> TEObject {
        operands.forEach {
            print($0)
        }
        
        return .Null
    }
}

