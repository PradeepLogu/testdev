TaxCloud.configure do |config|
	#config.api_login_id = '7BFCB90'
	#config.api_key = '30F81DB6-70CA-4C4E-B3A3-6DEC250635F4'
	config.api_login_id = "2EFB2150"
	config.api_key = "496D2F6F-1EDB-446B-A3A7-7C96763FABE6"
	#config.usps_username = ''
	config.ssl_version = :TLSv1
	config.ssl_verify_mode = :none
	config.ssl_cert_file = "CA/clientreq.pem"
	config.ssl_cert_key_file = "CA/clientkey.pem"
	#config.ssl_ca_cert_file = "CA/cacert.pem"
	config.ssl_cert_key_password = "+1r3sRu5"	
end