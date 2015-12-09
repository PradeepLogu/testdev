@geocoder = :google
if @geocoder == :bing
	# geocoding service (see below for supported options):
	Geocoder::Configuration.lookup = :bing
	Geocoder::Configuration.api_key = "ArW5u_MZDCbLaSabVyXCaOxN18AZnpdQawOJYvUlz33z9Uq9GYWz-a4ycWvk_6F2"
	Geocoder::Configuration.timeout = 8
elsif @geocoder == :google
	#Geocoder::Configuration.lookup = :google
	#Geocoder::Configuration.api_key = "AIzaSyDN7klZWRThWVSToj8LxWtfPC5wCzCSPW8"
	#Geocoder::Configuration.timeout = 8


	Geocoder.configure(
	  :lookup => :google,
	  :api_key => "AIzaSyDN7klZWRThWVSToj8LxWtfPC5wCzCSPW8",

	  # IP address geocoding service (see below for supported options):
	  #:ip_lookup => :maxmind,

	  # geocoding service request timeout, in seconds (default 3):
	  :timeout => 8,

	  # set default units to kilometers:
	  :units => :mi
	)
end