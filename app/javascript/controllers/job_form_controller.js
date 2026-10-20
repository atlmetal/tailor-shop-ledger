import { Controller } from "@hotwired/stimulus"

// The job form: fills in the price and materials of the service chosen, runs the − and + buttons, and keeps
// what the job charges, costs in materials and leaves up to date while the user types; in an advance, also the
// balance it leaves or, past it, what the customer would owe.
export default class extends Controller {
  static targets = [ "quantity", "price", "materialCost", "charged", "materials", "leaves", "balance", "jobCharged", "left", "leftAmount", "debt", "debtAmount" ]
  static values = { delimiter: String, unit: String }

  pickService({ target }) {
    this.#fill(this.priceTarget, target.dataset.price)
    this.#fill(this.materialCostTarget, target.dataset.materialCost)
  }

  decrease() {
    this.quantityTarget.stepDown()
    this.update()
  }

  increase() {
    this.quantityTarget.stepUp()
    this.update()
  }

  update() {
    const quantity = Number(this.quantityTarget.value) || 0
    const charged = quantity * this.#pesos(this.priceTarget)
    const materials = quantity * this.#pesos(this.materialCostTarget)

    this.chargedTarget.textContent = this.#format(charged)
    this.materialsTarget.textContent = this.#format(-materials)
    this.leavesTarget.textContent = this.#format(charged - materials)
    if (this.hasBalanceTarget) this.#updateBalance(charged)
  }

  #updateBalance(charged) {
    const left = Number(this.balanceTarget.dataset.balance) - charged

    this.jobChargedTarget.textContent = this.#format(-charged)
    this.leftAmountTarget.textContent = this.#format(left)
    this.debtAmountTarget.textContent = this.#format(-left)
    this.leftTarget.hidden = left < 0
    this.debtTarget.hidden = left >= 0
  }

  // Its own input event lets the money field group the digits; it bubbles up to update the summary.
  #fill(field, pesos) {
    field.value = pesos
    field.dispatchEvent(new Event("input", { bubbles: true }))
  }

  #pesos(field) {
    return Number(field.value.replace(/\D/g, "")) || 0
  }

  #format(pesos) {
    const digits = String(Math.abs(pesos)).replace(/\B(?=(\d{3})+$)/g, this.delimiterValue)
    return `${pesos < 0 ? "−" : ""}${this.unitValue}${digits}`
  }
}
