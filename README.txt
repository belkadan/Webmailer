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
