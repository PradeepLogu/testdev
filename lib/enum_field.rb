module EnumField
  class << self
    def included(klass)
      klass.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end
  end 

  module InstanceMethods
  end

  module ClassMethods
    def has_enum_field(column_name, data_set, options = {:validate => true, :scopes => true, :booleans => true})
      data_set.keys.each do |ds|
        dat = data_set[ds.to_sym]
        
        class_eval %{
          validates_inclusion_of :#{column_name}, :in => #{data_set}.keys  
        } if options[:validate] 

        class_eval %{
          scope :#{ds}, where('#{column_name} = ?', dat)
        } if options[:scopes] 

        class_eval %{
          def #{ds}?
            self[:#{column_name}] == #{data_set}[:#{ds}]
          end

          alias_method :is_#{ds}?, :#{ds}?
        } if options[:booleans] 

        class_eval %{
          def #{column_name}=(value)
            self[:#{column_name}] = value.is_a?(Integer) ? value : #{data_set}[value.to_sym]
          end

          def #{column_name}
            #{data_set}.key(self[:#{column_name}])
          end
        }
      end
    end
  end
end

ActiveRecord::Base.send(:include, EnumField)