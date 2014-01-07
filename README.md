SaneNetScanner [![Build Status](https://travis-ci.org/chrspeich/SaneNetScanner.png?branch=develop)](https://travis-ci.org/chrspeich/SaneNetScanner])
==============

A Mac OS X Scanner Driver for sane net devices

Client-Usage
------------

 1. Compile SaneNetScanner
 2. Copy `SaneNetScanner.app` to `/Library/Image Capture/Devices`
 3. Use `Image Capture`, `Preview` or any other compatible application to scan.

Server-Usage
------------

 1. Install, configure and start saned
 2. Install ruby-bindings for `dnssd` and `dbus`
 3. Run `scripts/publish-sane.rb`

FAQ
---

 1. **Q:** What is the state of the Project?
    
    **A:** It's working. The OSX-Client/Driver is quite stable and supports most functionally used by the os. The publish service is very rough and sometimes stops working (and saned sometimes, too). Development is currently stalled as all features I want are present. Feel free to send pull requests or contact me.
 2. **Q:** Why do we need `publish-sane.rb`? Saned already announces itself via bonjour!
    
    **A:** Yeah, saned already anncounes itself, but OSX needs to know about indivudal scanners in order to show it to the user. Therefore the extra script is needed.
