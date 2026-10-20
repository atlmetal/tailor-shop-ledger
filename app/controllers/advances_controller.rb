class AdvancesController < ApplicationController
  before_action :set_advance, only: %i[ edit update destroy ]

  def new
    @advance = Advance.new
  end

  # Then its first top-up.
  def create
    @advance = Advance.new(advance_params)

    if @advance.save
      redirect_to new_advance_top_up_path(@advance)
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @advance = Advance.includes(:top_ups, jobs: :service).find(params[:id])
  end

  def edit
  end

  def update
    if @advance.update(advance_params)
      redirect_to @advance
    else
      render :edit, status: :unprocessable_content
    end
  end

  # Only while it has no jobs, which counted. Its top-ups go with it.
  def destroy
    if @advance.destroy
      redirect_to root_path
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_advance
      @advance = Advance.find(params[:id])
    end

    def advance_params
      params.expect(advance: %i[ customer_name ])
    end
end
