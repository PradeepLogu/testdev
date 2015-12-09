require File.dirname(__FILE__) + '/helper'

describe "Redirect::App" do

  describe "/" do
    context "no redirect matches" do
      it "returns a 404 if no index exists" do
        @app = Redirect::App.new
        get '/'
        status.should == 404
        res["Content-Type"].should == "text/html"
        body.should == "not found"
      end

      it "returns a index.html if it exists" do
        @app = Redirect::App.new
        @app.public_dir = 'spec/fixtures/public'
        get '/'
        status.should == 200
        body.should == File.read('spec/fixtures/public/index.html')
      end
    end

    context "a redirect matches" do
      it "should redirect '/' if redirect exists" do
        @app = Redirect::App.new(['/', '/test'])
        get '/'
        headers['Location'].should == '/test'
        headers['Content-Type'].should == 'text/html'
        body.should == 'Redirecting to: /test'
      end
    end
  end

  describe "/sitemap.xml" do
    it "returns the sitemap xml" do
      @app = Redirect::App.new(['/', '/test', {:name => 'test'}])
      get '/sitemap.xml'
      headers['Content-Type'].should == 'text/xml'
      body.should == %(<?xml version="1.0" encoding="UTF-8"?>\n) +
      %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n) +
      %(<url>\n) +
        %(<loc>http://example.org/test</loc>\n) +
        %(</url>\n) +
      %(</urlset>\n)
    end

    it "ignores unnamed redirects" do
      @app = Redirect::App.new(['/a', '/hidden'])
      get('/sitemap.xml')
      body.should == %(<?xml version="1.0" encoding="UTF-8"?>\n) +
      %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n) +
      %(</urlset>\n)
    end
  end

  describe "static files" do
    before do
      @app = Redirect::App.new
      @app.public_dir = 'spec/fixtures/public'
    end

    it "serves GET requests for files in the public directory" do
      get "/index.html"
      status.should == 200
      body.should == File.read('spec/fixtures/public/index.html')
      headers['Content-Length'].should == '43'
      headers.should include('Last-Modified')
    end

    it "serves GET request for dirs if it contains index.html" do
      get "/sub"
      status.should == 200
      body.should == File.read('spec/fixtures/public/sub/index.html')
    end

    it "ignores GET request up the public directory" do
      get "/../private"
      status.should == 404
    end

    it "ignores GET request with .." do
      get "/../public/index.html"
      status.should == 404
    end

    it "ignores GET requests for dirs in the public directory" do
      get "/dir"
      status.should == 404
    end
  end

  describe "404" do
    it "shows 404 not found if no redirect exists" do
      @app = Redirect::App.new
      get("/test")
      res.not_found?.should be_true
      headers["Content-Type"].should == "text/html"
      body.should == "not found"
    end
  end

  describe "redirect" do
    context "basic redirect" do
      let(:res) do
        @app = Redirect::App.new(['/old/2008', '/index.html'])
        get '/old/2008'
      end

      it "sets the content-type header to text/html" do
        headers['Content-Type'].should == 'text/html'
      end

      it "sets the Location header to text/html" do
        headers['Location'].should == '/index.html'
      end

      it "sets the body to redirecting text/html" do
        body.should == 'Redirecting to: /index.html'
      end
    end

    it "can handle the redirected response" do
      @app = Redirect::App.new(['/old/2008', '/index.html'])
      @app.public_dir = 'spec/fixtures/public'
      get '/old/2008'
      status.should == 301
      get '/index.html'
      status.should == 200
      body.should == File.read('spec/fixtures/public/index.html')
    end

    it "renders the redirect if available" do
      @app = Redirect::App.new(['/old/2008', '/index.html'])
      @app.public_dir = 'spec/fixtures/public'
      get '/index.html'
      status.should == 200
      body.should == File.read('spec/fixtures/public/index.html')
    end

    it "redirects a regular_expression" do
      @app = Redirect::App.new(['^/old', '/new'])
      @app.public_dir = 'spec/fixtures/public'
      get '/old/2008'
      headers['Location'].should == '/new'
    end

    it "redirects a regular_expression with arguments" do
      @app = Redirect::App.new([/old\/(.*)/, '/new/$1'])
      get '/old/2008/02/14'
      headers['Location'].should == '/new/2008/02/14'
    end

    it "redirects to the first match" do
      @app = Redirect::App.new(['^/old2', '/new'], ['^/old2', '/new2'])
      get '/old2008'
      headers['Location'].should == '/new'
    end

    it "should turn redirects array into Redirect Objects" do
      @app = Redirect::App.new(['^/old3', '/new', {:code => 307}], ['^/old2', '/new2', {:name => 'test'}])
      get "/test"
      res.not_found?.should be_true
      headers["Content-Type"].should == "text/html"
      body.should == "not found"
    end
  end

  describe "#initialize" do
    it "raises an error if a catch_url matches a redirect_url" #do
      # Redirect::App.new(['^/old', 'new'], ['^/new', 'old'])
    # end
  end

  describe "#public_dir" do
    it "defaults to public" do
      Redirect::App.new.public_dir.should == 'public'
    end
  end

  def body
    res.body
  end

  def get url
    @res = Rack::MockRequest.new(@app).get(url)
  end

  def headers
    res.headers
  end

  def res
    @res
  end

  def status
    res.status
  end
end

describe "Redirect::Data" do
  describe "#initialize" do
    it "turns an default array into a redirect object" do
      data = Redirect::Data.new('^/old3', '/new')
      data.catch_url.should == '^/old3'
      data.redirect_url.should == '/new'
      data.code.should == 301
      data.name.should == nil
    end

    it "turns an array into a redirect object" do
      data = Redirect::Data.new('^/old3', '/new', {:code => 307, :name => 'test'})
      data.catch_url.should == '^/old3'
      data.redirect_url.should == '/new'
      data.code.should == 307
      data.name.should == 'test'
    end
  end
end

describe "Redirect" do
  after do
    Redirect.default_code = 301
    Redirect.app = nil
    Redirect.autorun = true
  end

  describe ".default_code" do
    it "overwrites default http redirect code" do
      data = Redirect::Data.new('/a', '/b')
      data.code.should == 301
      Redirect.default_code = 307
      data = Redirect::Data.new('/a', '/b')
      data.code.should == 307
    end
  end

  describe ".app" do
    it "sets app" do
      Redirect.app.should == nil
      Redirect.app = 'a'
      Redirect.app.should == 'a'
    end
  end

  describe ".autorun" do
    it "sets autorun" do
      Redirect.autorun.should == true
      Redirect.autorun = false
      Redirect.autorun.should == false
    end
  end

end
