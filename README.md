twisted-caldav
==============

Ruby client for searching, creating, editing calendar and tasks.

Tested with ubuntu based calendar server installation.

It is a modified version of another caldav client under MIT license

https://github.com/n8vision/caldav-icloud

## INSTALL

gem install 'twisted-caldav'

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
