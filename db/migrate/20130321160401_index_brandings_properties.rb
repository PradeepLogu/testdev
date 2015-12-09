class IndexBrandingsProperties < ActiveRecord::Migration
  def up
  	execute "CREATE INDEX brandings_properties ON brandings USING GIN(properties)"
  end

  def down
	execute "DROP INDEX brandings_properties"
  end
end
