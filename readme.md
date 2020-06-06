# KinsaTherm

I received a Kinsa BLE thermometer as a gift, but to my dismay discovered that their proprietary app doesn't keep measurements in HealthKit.  Not to look a gift horse in the mouth, but I prefer to keep my private data private, where possible.  I reverse engineered the BT protocol to a sufficient degree that I could read the data off of the device as it is taking measurements.  This is my gift to you so that you can take ownership of your private health data, too.

This repo contains a Swift framework and a sample application.  You merely need to get an instance of a `ThermometerManager`, implement the `ThermometerObserver` protocol and let the manager know about your observer:

    ThermometerManager.shared.addObserver(self)

That's it.  You'll get notified of various events, like when the thermometer is connected, ready to take measurements, starts reading temperature, and comes back to you with a final reading.  Not a lot of rocket science.

Oh, and in case there was any doubt, this is not an official Kinsa project, trademarks belong to their respective owners, etc.
