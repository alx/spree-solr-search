Product.class_eval do
  acts_as_solr  :fields => [:name, :description, :is_active, {:price => :float}, 
                            :taxon_ids, :price_range, :taxon_names,
                            :brand_property, :color_option, :size_option],
                :facets=>[:taxon_names, :brand_option, :color_option, :size_option, :age_option]

  def taxon_ids
    taxons.map(&:id)
  end
  
  def is_active
    !deleted_at && 
      (available_on <= Time.zone.now) && 
        (Spree::Config[:allow_backorders] || count_on_hand > 0)
  end
  
  private
  
  def taxon_names
    taxons.map(&:name)
  end
  
  def price_range
    price_ranges = YAML.load(Spree::Config[:product_price_ranges])
    case price
      when 0..25
        price_ranges[0]
      when 25..50
        price_ranges[1]
      when 50..100
        price_ranges[2]
      when 100..200
        price_ranges[3]
      else
        price_ranges[4]
    end
  end
  
  def brand_option
    get_option_values('brand')
  end

  def color_option
    get_option_values('color')
  end

  def size_option
    get_option_values('size')
  end
  
  def age_option
    get_option_values('age')
  end
  
  def get_option_values(option_name)
    sql = <<-eos
      SELECT DISTINCT ov.id, ov.presentation
      FROM option_values AS ov
      LEFT JOIN option_types AS ot ON (ov.option_type_id = ot.id)
      LEFT JOIN option_values_variants AS ovv ON (ovv.option_value_id = ov.id)
      LEFT JOIN variants AS v ON (ovv.variant_id = v.id)
      LEFT JOIN products AS p ON (v.product_id = p.id)
      WHERE (ot.name = '#{option_name}' AND p.id = #{self.id});
    eos
    OptionValue.find_by_sql(sql).map(&:presentation)     
  end
end
