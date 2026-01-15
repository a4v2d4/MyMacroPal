import SwiftUI
import UIKit

// MARK: - Auto-Select TextField Modifier
/// A ViewModifier that automatically selects all text when a TextField becomes focused
struct AutoSelectTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { notification in
                guard let textField = notification.object as? UITextField else { return }
                
                // Small delay to ensure the text field is fully ready
                DispatchQueue.main.async {
                    textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
                }
            }
    }
}

extension View {
    /// Automatically selects all text when the text field is tapped/focused
    func autoSelectText() -> some View {
        self.modifier(AutoSelectTextFieldModifier())
    }
}

// MARK: - Alternative: Move Cursor to End
struct MoveCursorToEndModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { notification in
                guard let textField = notification.object as? UITextField else { return }
                
                DispatchQueue.main.async {
                    let endPosition = textField.endOfDocument
                    textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
                }
            }
    }
}

extension View {
    /// Moves the cursor to the end of the text when the text field is tapped/focused
    func moveCursorToEnd() -> some View {
        self.modifier(MoveCursorToEndModifier())
    }
}

