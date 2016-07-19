# TrailBot Watcher

TrailBot tracks changes in your servers' files and logs and triggers smart policies.

Smart policies are simple scripts that receive notifications every time a watched file changes. They trigger actions such as emailing someone, rolling files back or even shutting the system down.

TrailBot has three components:
+ [__Watcher__](https://github.com/stampery/trailbot-watcher): server demon that monitors your files and logs, registers file events and enforces the policies.
+ [__Vault__](https://github.com/stampery/trailbot-vault): backend that works as a relay for the watcher's settings and the file changes.
+ [__Client__](https://github.com/stampery/trailbot-vault): desktop app for managing watchers, defining policies and reading file events.

# Install

In your server, with [npm](https://www.npmjs.com/) do:
```
npm install -g trailbot-watcher
```

# Encryption

Trailbot uses end-to-end encryption for preserving your privacy and avoid any disclosure of sensitive information.

Not even us can know anything about your files and logs nor read your file events and settings. Pretty cool, huh?
