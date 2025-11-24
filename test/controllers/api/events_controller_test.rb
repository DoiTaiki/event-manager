require "test_helper"

class Api::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:one)
  end

  # GET /api/events
  test "should get index" do
    get api_events_url, as: :json
    assert_response :success
    assert_not_nil JSON.parse(response.body)
  end

  test "index should return all events" do
    get api_events_url, as: :json
    events = JSON.parse(response.body)
    assert_kind_of Array, events
    assert_equal Event.count, events.length
  end

  # GET /api/events/:id
  test "should show event" do
    get api_event_url(@event), as: :json
    assert_response :success
    event_data = JSON.parse(response.body)
    assert_equal @event.id, event_data["id"]
    assert_equal @event.title, event_data["title"]
  end

  test "should return 404 for non-existent event" do
    get api_event_url(id: 99999), as: :json
    assert_response :not_found
    error_data = JSON.parse(response.body)
    assert_equal "Event not found", error_data["error"]
  end

  # POST /api/events
  test "should create event" do
    assert_difference("Event.count") do
      post api_events_url,
           params: {
             event: {
               event_type: "Workshop",
               event_date: "2025-12-25",
               title: "New Event",
               speaker: "Workshop Instructor",
               host: "Tech Company",
               published: true
             }
           },
           as: :json
    end

    assert_response :created
    event_data = JSON.parse(response.body)
    assert_equal "New Event", event_data["title"]
    assert_equal "Workshop", event_data["event_type"]
    assert_equal true, event_data["published"]
  end

  test "should not create event with invalid data" do
    assert_no_difference("Event.count") do
      post api_events_url,
           params: {
             event: {
               title: ""
             }
           },
           as: :json
    end

    assert_response :unprocessable_entity
  end

  # PATCH /api/events/:id
  test "should update event" do
    patch api_event_url(@event),
          params: {
            event: {
              title: "Updated Title",
              published: true
            }
          },
          as: :json

    assert_response :success
    @event.reload
    assert_equal "Updated Title", @event.title
    assert_equal true, @event.published
  end

  test "should not update event with invalid data" do
    original_title = @event.title
    patch api_event_url(@event),
          params: {
            event: {
              title: ""
            }
          },
          as: :json

    assert_response :unprocessable_entity
    @event.reload
    assert_equal original_title, @event.title
  end

  test "should return 404 when updating non-existent event" do
    patch api_event_url(id: 99999),
          params: {
            event: {
              title: "Updated Title"
            }
          },
          as: :json

    assert_response :not_found
  end

  # DELETE /api/events/:id
  test "should destroy event" do
    assert_difference("Event.count", -1) do
      delete api_event_url(@event), as: :json
    end

    assert_response :no_content
  end

  test "should return 404 when destroying non-existent event" do
    assert_no_difference("Event.count") do
      delete api_event_url(id: 99999), as: :json
    end

    assert_response :not_found
  end

  test "should handle event params correctly" do
    post api_events_url,
         params: {
           event: {
             event_type: "Conference",
             event_date: "2025-12-31",
             title: "Year End Conference",
             speaker: "Conference Speaker",
             host: "Tech Corp",
             published: false
           },
           # Top-level params should be ignored
           extra_param: "should be ignored"
         },
         as: :json

    assert_response :created
    event_data = JSON.parse(response.body)
    assert_equal "Year End Conference", event_data["title"]
    assert_equal "Conference", event_data["event_type"]
    assert_equal false, event_data["published"]
  end
end
