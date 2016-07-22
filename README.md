# TrailBot Watcher

TrailBot tracks changes in your servers' files and logs and triggers smart policies.

Smart policies are simple scripts that receive notifications every time a watched file changes. They trigger actions such as emailing someone, rolling files back or even shutting the system down.

TrailBot has three components:
+ [__Watcher__](https://github.com/stampery/trailbot-watcher): server demon that monitors your files and logs, registers file events and enforces the policies.
+ [__Vault__](https://github.com/stampery/trailbot-vault): backend that works as a relay for the watcher's settings and the file changes.
+ [__Client__](https://github.com/stampery/trailbot-vault): desktop app for managing watchers, defining policies and reading file events.

# Installing a watcher
In your the server you want to monitor, simply do:
```
git clone https://github.com/stampery/trailbot-watcher
cd trailbot-watcher
npm install
npm run setup
```
The last command guides you through the process of configuring the Watcher and importing your Trailbot Client's public key. Then you will have a completely functional watcher and you will be ready to start watching files and defining policies from the [__Client__](https://github.com/stampery/trailbot-vault).

# Encryption

Trailbot uses end-to-end encryption for preserving your privacy and avoid any disclosure of sensitive information.

Not even us can know anything about your files and logs nor read your file events and settings. Pretty cool, huh?
