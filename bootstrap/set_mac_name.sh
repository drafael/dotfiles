#!/usr/bin/env zsh

name=$1

# will show up on the Mac itself and what will be visible to others when connecting to it over a local network
scutil --set ComputerName "$name"

# visible from the command line, and it’s also used by local and remote networks when connecting through SSH
scutil --set HostName "$name"

# used by Bonjour and visible through file sharing services like AirDrop
scutil --set LocalHostName "$name"
