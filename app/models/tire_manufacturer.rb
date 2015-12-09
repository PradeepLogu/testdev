include ApplicationHelper
include TireStoresHelper

class TireManufacturer < ActiveRecord::Base
  attr_accessible :name
  has_many :tire_models
  has_many :tire_sizes, :through => :tire_models
  
  attr_accessor :sort_order
  attr_accessor :wheeldiameter_filter, :tire_size_id_filter, :tire_category_id_filter, :tgp_category_id_filter
  attr_accessor :cost_per_tire_min_filter, :cost_per_tire_max_filter
  
  
  #Collect all distinct tire model / tire category combinations for this brand
  #Tire models are allowed to appear under more than one category
  def get_all_tire_categories
    cats = TireModelInfo.joins('INNER JOIN tire_models ON tire_models.tire_model_info_id = tire_model_infos.id',
                               'INNER JOIN tire_categories ON tire_models.tire_category_id = tire_categories.id')
                        .where(tire_manufacturer_id: self.id)
                        .select('DISTINCT tire_model_infos.id, tire_model_infos.tire_model_name, tire_categories.id AS "category_id", tire_categories.category_name AS "category_name"')
                        .order('tire_categories.id ASC, tire_model_infos.tire_model_name ASC')
    result = Hash.new
    cats.each do |c|
      cat_id = c[:category_id]
      result[cat_id] = {:category_name => c[:category_name], :models => []} if result[cat_id].nil?
      result[cat_id][:models] << {:id => c.id, :name => c.tire_model_name}
    end
    result
  end
  
  #Collect all distinct tire model / TGP category combinations for this brand
  #Tire models are allowed to appear under more than one category
  def get_all_tgp_tire_categories
    models = TireModelInfo.joins('INNER JOIN tire_models ON tire_models.tire_model_info_id = tire_model_infos.id')
                          .where(tire_manufacturer_id: self.id).where('tgp_category_id IS NOT NULL')
                          .select('DISTINCT tire_model_infos.id, tire_model_infos.tire_model_name, tire_models.tgp_category_id AS "category_id"')
                          .order('tire_model_infos.tire_model_name ASC')
    names = TireModel.tgp_categories
    result = Hash.new
    models.each do |m|
      cat_id = m[:category_id].to_i
      if cat_id != 0 && names[cat_id]
        result[cat_id] = {:category_name => names[cat_id], :models => []} if result[cat_id].nil?
        result[cat_id][:models] << {:id => m.id, :name => m.tire_model_name}
      end
    end
    result.sort
  end
  
  #Collect all distinct tire model / car type combinations for this brand
  def get_all_car_types
    models = TireModelInfo.joins('INNER JOIN tire_models ON tire_models.tire_model_info_id = tire_model_infos.id')
                         .select('tire_model_infos.*, tire_models.tire_code AS "tire_code", MIN(tire_models.orig_cost) AS "starting_cost"')
                         .where(tire_manufacturer_id: self.id)
                         .group('tire_code, tire_model_infos.id')
                         .order('tire_model_infos.tire_model_name ASC')
    #Also combine passenger and performance tires into a sorted list so the controller doesn't have to
    result = {'P-Z' => []}
    models.each do |m|
      type = (m.tire_code.blank? ? 'P' : m.tire_code)   #Missing tire_code is allowed: default to P
      m.starting_cost = (m.starting_cost.to_f / 100).to_money if m.starting_cost
      result[type] = [] if result[type].nil?
      result[type] << m
      result['P-Z'] << m if (type == 'P' || type == 'Z')
    end
    result
  end
  
  
  def paginated_model_listings(page_no)
    self.tire_models.paginate(page: page_no, :per_page => 50)
  end

  def tire_models
    @tire_models ||= find_models
  end
  
  def find_models
    TireModel.includes(:tire_manufacturer, :tire_size, :tire_category, :tire_model_info).where(conditions).order(models_sortorder)
             #.joins('LEFT OUTER JOIN tire_model_infos ON tire_models.tire_model_info_id = tire_model_infos.id')
             #.select('tire_models.*, tire_manufacturers.*, tire_sizes.*, tire_categories.*, tire_model_infos.stock_photo1_file_name AS "stock_photo1_file_name"')
  end
  
  #Conditions
  
  def conditions
    c = [(conditions_clauses.concat(filters_clauses)).join(' AND '), *(conditions_options.concat(filters_options))]
  end
  
  #this one is unconditional
  def tire_manufacturer_id_conditions
    ["tire_models.tire_manufacturer_id = ?", self.id]
  end
  
  def conditions_clauses
    conditions_parts.map { |condition| condition.first }
  end

  def conditions_options
    conditions_parts.map { |condition| condition[1..-1] }.flatten
  end
  
  def conditions_parts
    methods.grep(/_conditions$/).map { |m| send(m) }.compact
  end
  
  #Filters
  def wheeldiameter_filters
    ["tire_sizes.wheeldiameter = ?", wheeldiameter_filter] unless wheeldiameter_filter.blank?
  end

  def tire_size_id_filters
    ["tire_models.tire_size_id = ?", tire_size_id_filter] unless tire_size_id_filter.blank?
  end
  
  def tire_category_id_filters
    ["tire_models.tire_category_id = ?", tire_category_id_filter] unless tire_category_id_filter.blank?
  end
  
  def tgp_category_id_filters
    ["tire_models.tgp_category_id = ?", tgp_category_id_filter] unless tgp_category_id_filter.blank?
  end

  def cost_per_tire_min_filters
    ["(tire_models.orig_cost::float / 100) >= ?", cost_per_tire_min_filter] unless cost_per_tire_min_filter.blank?
  end

  def cost_per_tire_max_filters
    ["(tire_models.orig_cost::float / 100) <= ?", cost_per_tire_max_filter] unless cost_per_tire_max_filter.blank?
  end
  
  def filters
    [filters_clauses.join(' AND '), *filters_options]
  end

  def filters_clauses
    filters_parts.map { |filter| filter.first }
  end

  def filters_options
    filters_parts.map { |filter| filter[1..-1] }.flatten
  end

  def filters_parts
    methods.grep(/_filters$/).map { |m| send(m) }.compact
  end
  
  def models_sortorder
    case self.sort_order
    when SortOrder::SORT_BY_MANU_ASC
      "tire_manufacturers.name ASC"
    when SortOrder::SORT_BY_MANU_DESC
      "tire_manufacturers.name DESC"
    when SortOrder::SORT_BY_SIZE_ASC
      "tire_sizes.sizestr ASC"
    when SortOrder::SORT_BY_SIZE_DESC
      "tire_sizes.sizestr DESC"
    when SortOrder::SORT_BY_TYPE_ASC
      "tire_categories.category_name ASC"
    when SortOrder::SORT_BY_TYPE_DESC
      "tire_categories.category_name DESC"
    when SortOrder::SORT_BY_COST_PER_TIRE_ASC
      "tire_models.orig_cost ASC"
    when SortOrder::SORT_BY_COST_PER_TIRE_DESC
      "tire_models.orig_cost DESC"
    when SortOrder::SORT_BY_MODEL_NAME_ASC
      "tire_models.name ASC, tire_sizes.sizestr ASC"
    when SortOrder::SORT_BY_MODEL_NAME_DESC
      "tire_models.name DESC, tire_sizes.sizestr ASC"
    else
      "tire_models.name ASC, tire_sizes.sizestr ASC"
    end
  end
end
