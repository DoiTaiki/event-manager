class Api::EventsController < ApplicationController
  before_action :set_event, only: %i[show update destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  def index
    @events = Event.all
    render json: @events
  end

  def show
    render json: @event
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      render json: @event, status: :created
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      render json: @event, status: :ok
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def handle_not_found
    render json: { error: "Event not found" }, status: :not_found
  end

  def event_params
    # Only use params[:event] to avoid top-level parameters
    # Rails may parse JSON and show top-level params in logs, but we only use :event
    # This ensures we only process the nested event hash, ignoring any top-level params
    event_data = params.require(:event)
    event_data.permit(
      :event_type,
      :event_date,
      :title,
      :speaker,
      :host,
      :published
    )
  end
end
