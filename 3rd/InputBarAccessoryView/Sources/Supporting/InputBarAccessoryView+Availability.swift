


























import UIKit

@available(*, deprecated, message: "InputManager has been renamed to InputPlugin")
public typealias InputManager = InputPlugin

extension InputPlugin {
    
    @available(*, deprecated, message: "`handleInput(object:)` should return a `Bool` if handle was successful or now")
    func handleInput(of object: AnyObject) {
        _ = self.handleInput(of: object)
    }
}

extension AutocompleteCompletion {

    @available(*, deprecated, message: "`displayText` should no longer be used, use `context: [String: Any]` instead")
    public var displayText: String? {
        return text
    }
}

extension AutocompleteManager {



    @available(*, deprecated, message: "`isCaseSensitive` was replaced in favour of a more customizable `filterBlock: (String) -> (Bool)`")
    public var isCaseSensitive: Bool {
        get { return false }
        set {
            if newValue {
                filterBlock = { session, completion in
                    completion.text.contains(session.filter)
                }
            } else {
                filterBlock = { session, completion in
                    completion.text.lowercased().contains(session.filter.lowercased())
                }
            }
        }
    }
}

extension InputBarAccessoryView {

    /**
     The anchor constants used by the InputStackView

     ````
     V:|...-(padding.top)-(textViewPadding.top)-[InputTextView]-(textViewPadding.bottom)-[InputStackView.bottom]-...|

     H:|...-[InputStackView.left]-(textViewPadding.left)-[InputTextView]-(textViewPadding.right)-[InputStackView.right]-...|
     ````

     */
    @available(*, deprecated, message: "The `InputTextView` now resides in the `middleContentView` and thus this property has been renamed to `middleContentViewPadding`")
    public var textViewPadding: UIEdgeInsets {
        get {
            return middleContentViewPadding
        }
        set {
            middleContentViewPadding = newValue
        }
    }
}
