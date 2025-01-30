# vanity

2025 is the year of the linux desktop (for me, lol).

## What is this?

Vanity is a desktop shell built with GTK4 and Astal. The library "Astal" means "desk," so this project is my vanity.

It isn't pretty yet, but it is starting to get pretty functional.

## Why is this?

I've always wanted to learn to make native linux desktop applications, and have [bounced off gnome ecosystem development before in the past](https://github.com/hyperparabolic/move-top-panel), but this is my commitment to figuring it out now.

## Features

- Libraries (I'll eventually get around to publishing these in my flake, and will push them upstream to Astal if there's much demand).
  - [Device and DBus driven brightness management](./src/lib/brightness/device.vala)
  - [DBus idle inhibition via org.freedesktop.login1.Manager](./src/lib/idle)

