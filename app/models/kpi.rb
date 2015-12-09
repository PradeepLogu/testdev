module KPI
  class PageViewsBySource < Garb::Report
    attr_accessor :profile
    def initialize
      Garb::Session.login(ENV['GARB_LOGIN'], ENV['GARB_PW'])
      @profile = Garb::Management::Profile.all.first
      super(profile)
      self.metrics :pageviews
      self.dimensions :source
      self.sort :pageviews.desc
    end
    
    def to_a
      self.results.to_a.map{|r| [] << r.source << r.pageviews.to_i}
    end
  end

  class PageViewsByPath < Garb::Report
    attr_accessor :profile
    def initialize
      Garb::Session.login(ENV['GARB_LOGIN'], ENV['GARB_PW'])
      @profile = Garb::Management::Profile.all.first
      super(profile)
      self.metrics :pageviews
      self.dimensions :page_path
      self.sort :pageviews.desc
    end
    
    def to_a
      self.results.to_a.map{|r| [] << r.page_path << r.visits.to_i}
    end
  end
  
  class VisitsByCity < Garb::Report
    attr_accessor :profile
    def initialize
      Garb::Session.login(ENV['GARB_LOGIN'], ENV['GARB_PW'])
      @profile = Garb::Management::Profile.all.first
      super(profile)
      self.metrics :visits, :newVisits, :pageviewsPerVisit, :visitBounceRate
      self.dimensions :city
      self.sort :visits.desc
    end
    
    def setState(state)
      filters do
        eql(:region, state)
      end
    end
    
    def last_24_hours
      @start_date = Date.today - 1.day
      @end_date = Date.today
      to_a
    end
    
    def last_7_days
      @start_date = Date.today - 7.days
      @end_date = Date.today
      to_a
    end
    
    def last_month
      @start_date = Date.today - 1.month
      @end_date = Date.today
      to_a
    end
    
    def all_metrics
      ar3 = self.last_24_hours
      ar2 = self.last_7_days
      result = self.last_month
      
      ar2.each do |a|
        found = false
        result.each do |b|
          if a[0] == b[0]
            b << a[1] << a[2] << a[3] << a[4] << a[5]
            found = true
          end
        end
        
        if !found
          ar = []
          ar << a[0] << 0 << 0.0 << 0 << 0.0 << 0.0
          result << ar
        end
      end
      
      result.each do |a|
        if a.size <= 6
          a << 0 << 0.0 << 0 << 0.0 << 0.0
        end
      end
      
      ar3.each do |a|
        found = false
        result.each do |b|
          if b[0] == a[0]
            b << a[1] << a[2] << a[3] << a[4] << a[5]
            found = true
          end
        end
        
        if !found
          ar = []
          ar << a[0] << 0 << 0.0 << 0 << 0.0 << 0.0
          result << ar
        end
      end
      
      result.each do |a|
        if a.size <= 6
          a << 0 << 0.0 << 0 << 0.0 << 0.0 << 0 << 0.0 << 0 << 0.0 << 0.0
        elsif a.size <= 11
          a << 0 << 0.0 << 0 << 0.0 << 0.0
        end
      end
      
      result
    end
    
    def to_a
      self.results.to_a.map{|r| [] << r.city << r.visits.to_i << (r.visits.to_i == 0 ? 0 : (100.0 * r.new_visits.to_i) / r.visits.to_i).round(2) << r.new_visits.to_i << r.visit_bounce_rate.to_f.round(2) << r.pageviews_per_visit.to_f.round(2)}
    end
  end
  
  class VisitsByState < Garb::Report
    attr_accessor :profile
    def initialize
      if false
        Garb::Session.login(ENV['GARB_LOGIN'], ENV['GARB_PW'])
        @profile = Garb::Management::Profile.all.first
        super(profile)
        self.metrics :visits, :newVisits, :pageviewsPerVisit, :visitBounceRate
        self.dimensions :region
        self.sort :visits.desc
        
        filters do
          eql(:country, 'United States')
        end
      else
        access_token = "4/oBfxL0VKGXKZ9sTXS8WGftznitoREWZvCAoT46ipZok.AiedyHKdn7kb3oEBd8DOtNAjNtY0mwI#"
        user = Legato::User.new(access_token)
      end
    end
    
    def setState(state)
      filters do
        eql(:region, state)
      end
    end
    
    def last_24_hours
      @start_date = Date.today - 1.day
      @end_date = Date.today
      to_a
    end
    
    def last_7_days
      @start_date = Date.today - 7.days
      @end_date = Date.today
      to_a
    end
    
    def last_month
      @start_date = Date.today - 1.month
      @end_date = Date.today
      to_a
    end
    
    def all_metrics
      ar3 = self.last_24_hours
      ar2 = self.last_7_days
      result = self.last_month
      
      ar2.each do |a|
        found = false
        result.each do |b|
          if a[0] == b[0]
            b << a[1] << a[2] << a[3] << a[4] << a[5]
            found = true
          end
        end
        
        if !found
          ar = []
          ar << a[0] << 0 << 0.0 << 0 << 0.0 << 0.0
          result << ar
        end
      end
      
      result.each do |a|
        if a.size <= 6
          a << 0 << 0.0 << 0 << 0.0 << 0.0
        end
      end
      
      ar3.each do |a|
        found = false
        result.each do |b|
          if b[0] == a[0]
            b << a[1] << a[2] << a[3] << a[4] << a[5]
            found = true
          end
        end
        
        if !found
          ar = []
          ar << a[0] << 0 << 0.0 << 0 << 0.0 << 0.0
          result << ar
        end
      end
      
      result.each do |a|
        if a.size <= 6
          a << 0 << 0.0 << 0 << 0.0 << 0.0 << 0 << 0.0 << 0 << 0.0 << 0.0
        elsif a.size <= 11
          a << 0 << 0.0 << 0 << 0.0 << 0.0
        end
      end
      
      result
    end
    
    def map_it(ar)
      ar.to_a.map{|r| [] << r.region << r.visits.to_i << (r.visits.to_i == 0 ? 0 : (100.0 * r.new_visits.to_i) / r.visits.to_i).round(2) << r.new_visits.to_i << r.visit_bounce_rate.to_f.round(2) << r.pageviews_per_visit.to_f.round(2)}
    end
    
    def to_a
      map_it(self.results)
    end
  end

  class VisitsByDay < Garb::Report
    attr_accessor :profile
    def initialize
      Garb::Session.login(ENV['GARB_LOGIN'], ENV['GARB_PW'])
      @profile = Garb::Management::Profile.all.first
      super(profile)
      self.metrics :visits
      self.dimensions :month
      self.dimensions << :day
      self.sort :month
      self.sort :day
    end
    
    def to_a
      self.results.to_a.map{|r| [] << (r.month + "/" + r.day) << r.visits.to_i}
    end
  end

  class PageViewsByDay < Garb::Report
    attr_accessor :profile
    def initialize
      Garb::Session.login(ENV['GARB_LOGIN'], ENV['GARB_PW'])
      @profile = Garb::Management::Profile.all.first
      super(profile)
      self.metrics :visits
      self.dimensions :day
      self.dimensions << :month
      self.sort :month
      self.sort :day
    end
  end
end