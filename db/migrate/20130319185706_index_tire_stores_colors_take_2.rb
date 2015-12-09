class IndexTireStoresColorsTake2 < ActiveRecord::Migration
  def up
  	execute "CREATE INDEX tire_stores_colors ON tire_stores USING GIN(colors)"
  end

  def down
	execute "DROP INDEX tire_stores_colors"
  end
end
