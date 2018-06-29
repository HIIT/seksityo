class AddCountryToImpressions < ActiveRecord::Migration
  def change
    add_column :impressions, :country, :string
  end
end
