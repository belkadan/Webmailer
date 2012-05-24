Webmailer
========

Webmailer is an application and system preference pane that handles `mailto` URLs by opening the webmail program of your choice. It can also run shell scripts.

_Webmailer is not undergoing active development. [Read why][blog]._

[blog]: http://belkadan.com/blog/2012/05/Big-News/


Building
-------

Webmailer is currently set up to build with Xcode 3.1 or later; it is still using the Xcode 3 series in order to build for Mac OS X v10.5 (for PowerPC Macs as well as 32- and 64-bit Intel). It should be possible to build Webmailer for Mac OS X v10.6 or later using Xcode 4.

Webmailer has integrated support for updates via [Sparkle][]. Using Sparkle in a System Preferences pane is risky because another prefpane may have loaded it already, so Webmailer confines itself to features in the public download from 2008. The updating interface has been customized a bit, so the framework and several private headers are embedded in the repository. It should be possible to build Webmailer with a bleeding-edge version of Sparkle, but I haven't tried it.

  [Sparkle]: https://github.com/andymatuschak/Sparkle

### Targets ###

- Webmailer Daemon: This little app is what actually responds to mailto URLs.
	(Technically it should be called "Webmailer Agent".)
- Preference Pane: This is what shows up in System Preferences.
	It builds the Daemon as a dependency and copies it into Resources.
- Add Webmailer to Mail Handlers: Tries to force LaunchServices to recognize
	the Daemon as a mailto handler. In theory it's not necessary, in practice...
- Tests: Runs SenTestKit-based tests.
- Build All: Does exactly that.


### TESTING PROCEDURE for smart app choosing ###

TODO: someday, turn this into a script of some kind.

	BROWSERS = [Safari Chrome]
	for default in $BROWSERS:
		set default browser to $default

		open all $BROWSERS
		for next in $BROWSERS:
			open 'mailto:me' from $next --> $next
		open 'mailto:me' from Terminal --> $default
		quit all $BROWSERS

		for next in $BROWSERS:
			open $next
			open 'mailto:me' from $next --> $next
			open 'mailto:me' from Terminal --> $next
			quit $next

		open 'mailto:me' from Terminal --> $default
		quit all $BROWSERS


Credits
-------

Keystone uses the following code snippets or libraries, from coders much wiser than I. Thank you all!

- [Dave Batton][]'s DBBackgroundView, which I've been using for a long time for drawing colors, images, and gradients behind my main content. It seems to no longer be easily available on the internet, so I'm including the compiled framework here.

- [Andy Matuschak][]'s [Sparkle][] update framework (see note above).

- [Brandon Walkin][]'s BWHyperlinkButton, now part of [BWToolkit][]. (Interface Builder plugins are still a wonderful thing that Xcode 4 just doesn't have, but even if you forego them BWToolkit still has some very nice UI items to augment AppKit.)

  [Dave Batton]: http://twitter.com/#!/DaveBatton
  [Andy Matuschak]: http://andymatuschak.org/
  [Brandon Walkin]: http://www.brandonwalkin.com
  [BWToolkit]: http://brandonwalkin.com/bwtoolkit/


License
-------

_This license does not of course include the classes and libraries listed in the "credits" section, which belong to their respective owners._

 Copyright (c) 2006-2012 Jordy Rose
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 Except as contained in this notice, the name(s) of the above copyright holders
 shall not be used in advertising or otherwise to promote the sale, use or other
 dealings in this Software without prior authorization.

