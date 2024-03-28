class CreateSongs < ActiveRecord::Migration[6.1]
  def change
    create_table :songs do |t|
      t.string :name
      t.string :spotify_url
      t.references :band, foreign_key: true

      t.timestamps
    end
  end
end
