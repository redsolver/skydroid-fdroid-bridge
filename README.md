# SkyDroid F-Droid bridge

This bridge makes [F-Droid](https://f-droid.org/) apps available in the [SkyDroid App](https://github.com/redsolver/skydroid).

This bridge checks for updates in the main F-Droid Repo, downloads them, converts the metadata files into the SkyDroid format, uploads the metadata files to Skynet and sets DNS Records for the apps and collection via the [Namebase API](https://github.com/namebasehq/api-documentation).

It is part of my submission to the [‘Own The Internet’ Hackathon](https://gitcoin.co/hackathon/own-the-internet)

## How to use with SkyDroid

Add the `papagei`-collection in the SkyDroid App. (Migrating to `fdroid-app` soon)

## How to run this bridge

1. Copy `.env.example` to `.env` and change the values
2. Get the [Dart SDK](https://dart.dev/get-dart)
3. Run `dart bin/main.dart`