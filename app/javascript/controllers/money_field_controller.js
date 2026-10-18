import { Controller } from "@hotwired/stimulus"

// Lets a money field take digits only and groups them as the user types: 50000 shows as 50.000. It listens
// to input, since Android keyboards don't report keys reliably in keydown.
export default class extends Controller {
  static values = { delimiter: String }

  format({ inputType }) {
    const field = this.element
    let text = field.value
    // A pasted "$ 120.450,00" keeps its pesos and drops its cents, instead of becoming $12.045.000.
    if (inputType === "insertFromPaste" || inputType === "insertFromDrop") text = text.replace(/[.,]\d{1,2}(?=\D*$)/, "")

    const digitsBeforeCaret = text.slice(0, field.selectionStart).replace(/\D/g, "").length
    // Nine digits at most: an integer column holds a bit over two billion.
    const digits = text.replace(/\D/g, "").replace(/^0+(?=\d)/, "").slice(0, 9)
    field.value = digits.replace(/\B(?=(\d{3})+$)/g, this.delimiterValue)

    // The caret stays after the same digit, so a correction in the middle doesn't send it to the end.
    let caret = 0
    for (let seen = 0; seen < digitsBeforeCaret && caret < field.value.length; caret++) {
      if (/\d/.test(field.value[caret])) seen++
    }
    field.setSelectionRange(caret, caret)
  }
}
