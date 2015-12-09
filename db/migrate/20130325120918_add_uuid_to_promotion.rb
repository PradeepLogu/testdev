class AddUuidToPromotion < ActiveRecord::Migration
  def change
    add_column :promotions, :uuid, :string
  end
end
