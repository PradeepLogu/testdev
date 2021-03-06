class Money

  # Converts an object of this instance into a database friendly value.
  def mongoize
    {
      :cents        => cents,
      :currency_iso => currency.iso_code
    }
  end

  class << self

    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      return nil if object.nil?

      ::Money.new(object[:cents], object[:currency_iso])
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      case object
      when Money then object.mongoize
      when Hash then ::Money.new(object[:cents], object[:currency]).mongoize
      else object
      end
    end

    # Converts the object that was supplied to a criteria and converts it
    # into a database friendly form.
    def evolve(object)
      case object
      when Money then object.mongoize
      else object
      end
    end
  end
end
