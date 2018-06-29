class ChangeImpressionColumnName < ActiveRecord::Migration
  def change
    rename_column :impressions, :type, :impression_type
  end
end
