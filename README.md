# TrailBot Watcher

TrailBot tracks changes in your servers' files and logs and triggers smart policies.

Smart policies are simple scripts that receive notifications every time a watched file changes. They trigger actions such as emailing someone, rolling files back or even shutting the system down.

TrailBot has three components:
+ [__Watcher__](https://github.com/stampery/trailbot-watcher): a server demon that monitors your files and logs and enforces the policies.
+ [__Vault__](https://github.com/stampery/trailbot-vault): a backend that serves as a relay for the watcher's settings and the file changes.
+ [__Client__](https://github.com/stampery/trailbot-vault): a desktop app for managing watchers, defining policies and reading file changes events.


# Install

With [npm](https://www.npmjs.com/) do:
```
npm install -g trailbot-watcher
```
