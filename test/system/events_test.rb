require "application_system_test_case"

class EventsTest < ApplicationSystemTestCase
  setup do
    @event = events(:one)
    visit root_path
  end

  test "visiting the index" do
    # Wait for React to load
    assert_selector "h2", text: "Events", wait: 10
  end

  test "should display events list" do
    # Wait for React to load and events to be displayed
    assert_selector ".eventList", wait: 10
    assert_selector ".eventList ul li", minimum: 1, wait: 10
  end

  test "should create an event" do
    # Wait for events list to load
    assert_selector ".eventList", wait: 10

    # Click on "New Event" link
    click_on "New Event"

    # Wait for form to appear
    assert_selector ".eventForm", wait: 10

    # Fill in the form
    fill_in "event_type", with: "Conference"
    fill_in "event_date", with: "2025-12-25"
    fill_in "title", with: "Test Event"
    fill_in "speaker", with: "Test Speaker"
    fill_in "host", with: "Tech Corp"
    check "published"

    # Submit the form
    click_on "Save"

    # Wait for the success notification and navigation
    assert_text "Event Added!", wait: 10
    assert_text "Test Event", wait: 10
  end

  test "should update an event" do
    # Wait for events list to load
    assert_selector ".eventList", wait: 10

    # Click on the first event link
    first(".eventList ul li a").click

    # Wait for event details to load
    assert_selector ".eventContainer", wait: 10

    # Click Edit link
    click_on "Edit"

    # Wait for form to appear
    assert_selector ".eventForm", wait: 10

    # Update the title
    fill_in "title", with: "Updated Event Title"
    click_on "Save"

    # Wait for the success notification
    assert_text "Event Updated!", wait: 10
    assert_text "Updated Event Title", wait: 10
  end

  test "should delete an event" do
    # Wait for events list to load
    assert_selector ".eventList", wait: 10

    # Get the initial count
    initial_count = all(".eventList ul li").length

    # Click on the first event link
    first(".eventList ul li a").click

    # Wait for event details to load
    assert_selector ".eventContainer", wait: 10

    # Click delete button
    accept_confirm do
      click_on "Delete"
    end

    # Wait for the success notification and return to events list
    assert_text "Event Deleted!", wait: 10
    assert_selector ".eventList", wait: 10

    # Verify the event was removed (one less event)
    assert_equal initial_count - 1, all(".eventList ul li").length
  end

  test "should search events" do
    # Wait for events list to load
    assert_selector ".eventList", wait: 10

    # Type in search box
    fill_in "Search", with: "Conference"

    # Wait for filtered results
    assert_selector ".eventList ul li", wait: 10
  end

  test "should show event details" do
    # Wait for events list to load
    assert_selector ".eventList", wait: 10

    # Click on the specific event link (matching the event's date and type)
    event_link_text = "#{@event.event_date} - #{@event.event_type}"
    click_on event_link_text

    # Wait for event details to load
    assert_selector ".eventContainer", wait: 10

    # Verify event details are displayed
    assert_text @event.title, wait: 10
    assert_text @event.event_type, wait: 10
    assert_text @event.speaker, wait: 10
  end

  test "should display validation errors" do
    # Wait for events list to load
    assert_selector ".eventList", wait: 10

    # Click on "New Event" link
    click_on "New Event"

    # Wait for form to appear
    assert_selector ".eventForm", wait: 10

    # Try to save without required fields (leave title empty)
    fill_in "title", with: ""
    click_on "Save"

    # Verify error messages are displayed
    assert_selector ".errors", wait: 10
    assert_text "errors prohibited", wait: 10
  end

  test "should cancel event creation" do
    # Wait for events list to load
    assert_selector ".eventList", wait: 10

    # Click on "New Event" link
    click_on "New Event"

    # Wait for form to appear
    assert_selector ".eventForm", wait: 10

    # Click Cancel
    click_on "Cancel"

    # Should return to events list
    assert_selector ".eventList", wait: 10
  end

  test "should navigate between events" do
    # Wait for events list to load
    assert_selector ".eventList", wait: 10

    # Click on the first event
    first(".eventList ul li a").click

    # Wait for event details
    assert_selector ".eventContainer", wait: 10

    # Go back to events list (click on header or navigate)
    visit root_path

    # Should see events list again
    assert_selector ".eventList", wait: 10
  end
end
