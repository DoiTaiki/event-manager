# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
json = ActiveSupport::JSON.decode(File.read(Rails.root.join('db', 'seeds', 'events.json')))
json.each do |record|
  Event.find_or_create_by!(title: record['title'], event_date: record['event_date']) do |event|
    event.event_type = record['event_type']
    event.speaker = record['speaker']
    event.host = record['host']
    event.published = record['published']
  end
end
