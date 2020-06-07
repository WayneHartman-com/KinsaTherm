# KinsaTherm

I received a Kinsa BLE thermometer as a gift, but to my dismay discovered that their proprietary app doesn't keep measurements in HealthKit.  Not to look a gift horse in the mouth, but I prefer to keep my private data private, where possible.  I [reverse engineered](https://waynehartman.com/posts/reverse-engineering-the-kinsa-smart-thermometer.html) the BT protocol to a sufficient degree that I could read the data off of the device as it is taking measurements.  This is my gift to you so that you can take ownership of your private health data, too.

This repo contains a Swift framework and a sample application.  You merely need to get an instance of a `ThermometerManager`, implement the `ThermometerObserver` protocol and let the manager know about your observer:

    ThermometerManager.shared.addObserver(self)

That's it.  You'll get notified of various events, like when the thermometer is connected, ready to take measurements, starts reading temperature, and comes back to you with a final reading.  Not a lot of rocket science.

Oh, and in case there was any doubt, this is not an official Kinsa project, trademarks belong to their respective owners, etc.

If you're interested in creating your own implementation for another platform, below are the byte mapping for temperature readings:

## Intermediate Temperature Reading

Example bytes: `42000170`

1. **`42`** - Intermediate temperature reading header.
2. **`00`** - Sequence byte.  Increments with each subsequent reading.
3. **`01`** - First byte of the temperature.
4. **`70`** - Second byte of the temperature.

## Final Temperature Reading

Example bytes: `46000170000038`  

1. **`46`** - Final temperature reading header.
2. **`00`** - Always 0. Reserved for some future use.
3. **`01`** - First byte of the temperature.
4. **`70`** - Second byte of the temperature.
5. **`00`** - Always 0. Reserved for some future use.
6. **`00`** - Always 0. Reserved for some future use.
7. **`38`** - Unknown.  No discernible pattern.  Some sort of confidence or error byte?

## Device System Clock Message

Example bytes: `06140607102106`

1. **`06`** - Date/Time header
2. **`14`** - Year #Y2K
3. **`06`** - Month
4. **`07`** - Day
5. **`10`** - Hour (expressed in 24 hour time)
6. **`21`** - Minute
7. **`06`** - Second


