module Redirect

  class App

    class StaticFile
      def initialize(path)
        @path = path
        @path = File.join(path, 'index.html') unless available?
      end

      def available?
        expanded_path && expanded_path == path && File.file?(expanded_path)
      end

      def path
        @path
      end

      def expanded_path
        File.expand_path(path)
      end

    end

    attr_reader :redirects
    attr_accessor :public_dir

    def initialize(*redirects)
      @redirects = redirects.collect do |r|
        Data.new(*r)
      end
    end

    def call(env)
      @env = env
      @request = Rack::Request.new(env)
      if static_file.available?
        return static_response
      end
      if request.fullpath == '/sitemap.xml'
        return sitemap_response
      end
      # if request.fullpath == '/' && index_file.available?
        # return index_response
      # end
      @redirects.each do |r|
        if r.matches?(request.fullpath)
          return redirects_response(r)
        end
      end
      not_found_response
    end

    def public_dir
      @public_dir ||= 'public'
    end

    private
      def env
        @env
      end

      def request
        @request
      end

      # def index_response
      #   send_file(index_file.expanded_path)
      # end

      # def index_file
      #   @index_file = StaticFile.new(File.join(public_dir_path, 'index.html'))
      # end

      def public_dir_path
        File.expand_path(public_dir)
      end

      def not_found_response
        [404, {"Content-Type" => "text/html"}, ["not found"]]
      end

      def redirects_response(r)
        puts "Match found for #{r.catch_url}."
        puts "Redirecting to #{r.redirect_url}"
        return [r.code, {"Location" => r.redirect_url, "Content-Type" => "text/html"}, ["Redirecting to: #{r.redirect_url}"]]
      end

      def send_file(path, opts={})
        # if opts[:type] or not response['Content-Type']
          # content_type ::File.extname(path), :default => 'application/octet-stream'
        # end
        # last_modified opts[:last_modified] if opts[:last_modified]
        file = Rack::File.new public_dir_path
        file.path = path
        file.serving env
      rescue Errno::ENOENT
        not_found_response
      end

      def sitemap_response
        [200, {"Content-Type" => "text/xml"}, [sitemap(request.host)]]
      end

      def sitemap(host)
        %(<?xml version="1.0" encoding="UTF-8"?>\n) +
        %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n) +
        @redirects.select{|r| r.name }.collect { |r|
          %(<url>\n) +
            %(<loc>http://#{host}#{r.redirect_url}</loc>\n) +
          %(</url>\n)}.join +
        %(</urlset>\n)
      end

      def static_file
        StaticFile.new(public_dir_path + URI.unescape(request.path_info))
      end

      def static_response
        send_file static_file.expanded_path
      end

  end
end
