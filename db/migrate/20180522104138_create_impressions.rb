class CreateImpressions < ActiveRecord::Migration
  def change
    create_table :impressions do |t|
      t.string :type
      t.string :session
      t.string :country_code
      t.string :latitude
      t.string :longitude
      t.string :status

      t.timestamps null: false
    end
  end
end
