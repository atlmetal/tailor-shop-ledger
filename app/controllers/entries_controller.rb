class EntriesController < ApplicationController
  before_action :set_entry, only: %i[ edit update destroy ]
  before_action :set_latest_entries, only: %i[ new create ]

  def new
    @entry = Entry.new(kind:, occurred_on: Date.current)
  end

  def create
    @entry = Entry.new(entry_params.merge(kind:))

    if @entry.save
      redirect_to record_return_path(@entry.occurred_on)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @entry.update(entry_params)
      redirect_to record_return_path(@entry.occurred_on)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @entry.destroy!
    redirect_to record_return_path(@entry.occurred_on)
  end

  private
    # "expense" or "income", from the route's defaults.
    def kind
      params.expect(:kind)
    end

    def set_entry
      @entry = Entry.where(kind:).find(params[:id])
    end

    def set_latest_entries
      @latest_entries = Entry.where(kind:).latest
    end

    def entry_params
      params.expect(entry: %i[ occurred_on concept amount ])
    end
end
