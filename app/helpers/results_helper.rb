# A result always shows its word and icon, never its color alone.
module ResultsHelper
  # "Ganancia" with a check from 0 up, "Pérdida" with an alert below it.
  def result_word(result)
    render(result.total.negative? ? "shared/loss_word" : "shared/profit_word")
  end

  def result_amount_class(result)
    "text-loss-ink" if result.total.negative?
  end
end
