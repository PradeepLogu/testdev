1. To generate the certs, I used the guides here:
	https://www.balabit.com/sites/default/files/documents/syslog-ng-ose-latest-guides/en/syslog-ng-tutorial-mutual-auth-tls/html/mutual-authentication-certificates.html

2. The openssl.cnf file is located at /usr/local/etc/openssl and not /etc/ssl, so for step #3 on "1.1 Procedure - Creating an SA", use this command instead:
	cp /usr/local/etc/openssl/openssl.cnf .

3. I used a passphrase of "+1r3sRu5", FWIW.

4. To test the connectivity of the certs with TaxCloud, use the following command.  If there are no errors, it should work when actually connecting with Ruby :)
	curl -v  -cert  clientreq.pem --key clientreq.key  https://api.taxcloud.net/1.0/TaxCloud.asmx?WSDL
