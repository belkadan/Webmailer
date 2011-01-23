TARGETS:
- Webmailer Daemon: This little app is what actually responds to mailto URLs.
	(Technically it should be called "Webmailer Agent".)
- Preference Pane: This is what shows up in System Preferences.
	It builds the Daemon as a dependency and copies it into Resources.
- Add Webmailer to Mail Handlers: Tries to force LaunchServices to recognize
	the Daemon as a mailto handler. In theory it's not necessary, in practice...
- Tests: Runs SenTestKit-based tests.
- Build All: Does exactly that.


TESTING PROCEDURE for smart app choosing
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
