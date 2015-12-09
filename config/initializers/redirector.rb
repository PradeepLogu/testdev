module Redirector
  class Middleware
    class Responder
      def redirect_response
        [301, {'Location' => redirect_url_string}, [%{You are being redirected <a href="#{redirect_url_string}">#{redirect_url_string}</a>}]]
      end

      def redirect_uri
        destination_uri.tap do |uri|
          uri.scheme ||= 'http'
          uri.host   ||= request_host
          uri.port   ||= request_port.to_i unless request_port.nil?
        end
      end

      def request_port
        env['HTTP_HOST'].split(':').second
      end
    end
  end
end