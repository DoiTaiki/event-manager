require "test_helper"

class EventTest < ActiveSupport::TestCase
  def setup
    @event = events(:one)
  end

  test "should be valid" do
    assert @event.valid?
  end

  test "should have required attributes" do
    event = Event.new(
      event_type: "Conference",
      event_date: Date.today,
      title: "Test Event",
      speaker: "Test Speaker",
      host: "Tech Corp",
      published: true
    )
    assert event.valid?
  end

  test "id should be readonly" do
    original_id = @event.id
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      @event.update(id: 999)
    end
    assert_equal original_id, @event.reload.id
  end

  test "created_at should be readonly" do
    original_created_at = @event.created_at
    @event.created_at = 1.day.ago
    @event.save
    assert_equal original_created_at.to_i, @event.reload.created_at.to_i
  end

  test "should allow updating event attributes" do
    @event.update(title: "Updated Title")
    assert_equal "Updated Title", @event.reload.title
  end

  test "should allow updating published status" do
    @event.update(published: true)
    assert @event.reload.published
  end
end
