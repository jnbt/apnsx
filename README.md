APNSx
=====

[![Build Status](https://travis-ci.org/jnbt/apnsx.svg)](https://travis-ci.org/jnbt/apnsx)
[![Inline docs](https://inch-ci.org/github/jnbt/apnsx.svg)](https://inch-ci.org/github/jnbt/apnsx)

:construction: :warning:
**This project is in very stage. Things will change!**

## Usage

Initialize a client process to interact with the APNS:

```elixir
host = "gateway.push.apple.com"
cert = "path/to/apns_production.pem"
{:ok, client} = APNSx.Client.start(host, 2195, cert: [path: cert])
```

### Pushing notifications

Use the process to push notifications:

```elixir
APNSx.Client.push(client, %APNSx.Notification{
  device_token: "ce8be627 2e43e855 16033e24 b4c28922 0eeda487 9c477160 b2545e95 b68b5969",
  payload: ~s({"aps": {"badge": 1}),
  id: 10001,
  expiry: 86400000,
  priority: 5
})
```

As Apple changed the [Notification Payload](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1) format several time this tool **doesn't** generate a payload.
It's your responsibility to provide a correctly formatted JSON payload.
(You might want to checkout [Poison](https://github.com/devinus/poison) for the JSON encoding).

### Feedback

**TODO: Add description about feedback channel** 


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

Jonas Thiel ([@jonasthiel](https://twitter.com/jonasthiel))

## References

For more information about the APNS have a look at the [Apple's documentation](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Introduction.html).

## Testing

Dummy SSL certificates are included for testing. Just run the tests:

```bash
$ mix test
```

## Contributing

1. [Fork it!](https://github.com/jnbt/apnsx/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

This software is released under the MIT License. See the LICENSE file for further details.
