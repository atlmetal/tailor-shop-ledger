module JobsHelper
  # "Guardado: 2 × Basta de pantalón, $16.000. Sigue con el próximo.", after "Guardar y registrar otro".
  def job_saved_notice
    render("jobs/saved", job: flash[:saved]) if flash[:saved]
  end
end
