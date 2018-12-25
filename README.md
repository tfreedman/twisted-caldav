twisted-caldav
==============

Note: This is a fork of twisted-caldav, a Ruby gem that was supposed to let you manage calendar and to-do list entries. From looking at the source code, I have doubts that it actually enabled you to do some of those things correctly. I've been slowly fixing those bugs for a separate project of mine, and this is where any fixes to those libraries go. Eventually, when I have verified that the library actually works, I'll publish it under a different name on Rubygems, since it now handles CalDAV as well as CardDAV, and implements various other important things that the original library never did, like calendar / address book discovery.

A Ruby CalDAV / CardDAV client, for managing events, contacts, and tasks.

A modified version of [twisted-caldav](https://github.com/NopMind/twisted-caldav), released under the MIT license.

Note: CalDAV and CardDAV are transport protocols, not file formats, and this library only manages the "how to talk to a server" part. To actually craft an iCalendar file (which is what Calendar / To-Do list entries are), you'll want to use [Icalendar](https://github.com/icalendar/icalendar/), and to craft vCard entries you'll want to use [vCardigan](https://github.com/brewster/vcardigan).

## INSTALL

Add: ```gem 'twisted-caldav', git: 'https://github.com/tfreedman/twisted-caldav.git'```
to your Gemfile, then run ```bundle install```

## USAGE

```require ’twisted-caldav'```

```cal = TwistedCaldav::Client.new(uri: "http://yourserver.com:8008/calendars/users/admin/calendar/", user: "username" , password: "xxxxxx")```

### FIND EVENTS

All:

```result = cal.find_events```

By date:

```result = cal.find_events(start: "2014-04-01", end: "2014-04-15")```

By name:

```result = cal.find_events(summary: 'Boston')```

### FIND TODOS

All:

```result = cal.find_todos```

By name:

```result = cal.find_todos(summary: 'Groceries')```

### CREATE EVENT

```result = cal.create_event(start: "2014-04-12 10:00", end: "2014-04-12 12:00", title: "Meeting With Me", description: "Meeting about nothing...:D")```
