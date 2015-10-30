APNSx
=====

[![Build Status](https://travis-ci.org/jnbt/apnsx.svg)](https://travis-ci.org/jnbt/apnsx)
[![Inline docs](https://inch-ci.org/github/jnbt/apnsx.svg)](https://inch-ci.org/github/jnbt/apnsx)

** TODO: Add description **

## Converting your certificate

Once you have the certificate from Apple for your application, export your key and the apple certificate as p12 files. Here is a quick walkthrough on how to do this:

1. Click the disclosure arrow next to your certificate in Keychain Access and select the certificate and the key.
2. Right click **only** the certificate entry (e.g. "Apple Production IOS Push Service: …") and choose "… export"
3. Choose the p12 format from the drop down and name it cert.p12.
4. Now covert the p12 file to a PEM file:

```
$ openssl pkcs12 -in cert.p12 -out apple_push_notification.pem -nodes -clcerts
```

If you have any trouble when using the PEM file in Erlang's SSL module open the converted `.pem` file in your favorite text editor.
Check that every block (certifcate / private key) exists only once in this file. Remove duplicated entries if needed.

## Author

Jonas Thiel (@jonasthiel)

## References

For more information about the APNS have a look at the [Apple's documentation](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Introduction.html).

## License

This software is released under the MIT License. See the LICENSE file for further details.
