# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


10.times do |index|
  band = Band.create(name: Faker::Music.band)
  4.times do |song|
    band.songs.create(name: Faker::Music.album, spotify_url: "https://example.com")
  end
end