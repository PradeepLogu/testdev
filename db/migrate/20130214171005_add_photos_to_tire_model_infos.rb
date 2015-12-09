class AddPhotosToTireModelInfos < ActiveRecord::Migration
  def change
  	add_attachment :tire_model_infos, :stock_photo1
  	add_attachment :tire_model_infos, :stock_photo2
  	add_attachment :tire_model_infos, :stock_photo3
  	add_attachment :tire_model_infos, :stock_photo4
  end
end
