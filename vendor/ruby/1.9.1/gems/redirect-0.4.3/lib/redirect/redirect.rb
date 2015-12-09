module Redirect

  def self.default_code= default_code
    @default_code = default_code
  end

  def self.default_code
    @default_code ||= 301
  end

  def self.autorun= autorun
    @autorun = autorun
  end

  def self.autorun
    @autorun = true unless @autorun == false
    @autorun
  end

  def self.app= app
    @app = app
  end

  def self.app
    @app
  end

  class Data
    attr_reader :catch_url, :code, :match, :name
    def initialize(catch_url, redirect_url, options = {})
      @catch_url = catch_url
      @redirect_url = redirect_url
      @code = options[:code] || Redirect.default_code
      @name = options[:name]
    end

    def matches?(url)
      matched = url.match(catch_url)
      @match = $1
      matched
    end

    def redirect_url
      if @match
        @redirect_url.gsub('$1', @match)
      else
        @redirect_url
      end
    end
  end

end

def redirect(*redirects)

  Redirect.app = Redirect::App.new(*redirects)
  if Redirect.autorun
    Rack::Handler::WEBrick.run \
      Rack::ShowExceptions.new(Rack::Lint.new(Redirect.app)),
      :Port => 3000
    run Redirect.app
  end
end
