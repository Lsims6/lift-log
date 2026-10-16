# Lift Log

An offline workout tracker for iPhone. Everything is saved in a file on the phone; nothing goes over the internet.

## What's here

- `LiftLog/Web/index.html`: the whole app screen (workouts, per-set logging, progressive overload, finish & lock, body-weight tracking, progress charts, history, CSV import/export). Open it in any browser to try it out; there it saves to the browser instead of the phone.
- `LiftLog/LiftLogApp.swift`: the small iPhone shell that shows the page and saves the log to `Documents/lift-log.json` (with a backup copy).
- `LiftLogUITests/`: an automatic test on a simulated iPhone: logs a set, closes the app, reopens it, and checks the set is still there.
- `project.yml`: the Xcode project definition (the build generates the `.xcodeproj` from it with XcodeGen).
- `.github/workflows/build.yml`: builds and tests on a cloud Mac on every push.

## Getting the app

1. Open the **Actions** tab and click the latest **Build Lift Log** run.
2. Check that it has a green check mark, then download **LiftLog-ipa** under *Artifacts* and unzip it to get `LiftLog.ipa`.
3. The **screenshots** artifact shows the app running on a simulated iPhone.
4. Install `LiftLog.ipa` with AltStore: **My Apps → + →** pick the file.

## Moving data

- **Export CSV** (History tab) opens the share sheet: save to Files, AirDrop, or email.
- **Import CSV** reads a file exported from Lift Log (the web version or this app). Past days come in as finished workouts.
- Body weight is exported as rows with the exercise "Body weight" and the weight in the Weight column, and comes back in on import.

Your log lives inside the app. Refreshing it in AltStore keeps your data, but deleting the app deletes the log, so export a CSV now and then as a backup.

## Appetize (try it in a browser)

Every build that passes its test can be sent to [Appetize](https://appetize.io), which runs the app on a virtual iPhone in your browser.

1. In Appetize, create an API token (account settings → API token).
2. In this repo: **Settings → Secrets and variables → Actions → New repository secret**, name it `APPETIZE_API_TOKEN`, and paste the token.
3. Optional, to keep one link that always has the newest build: open the app in your Appetize dashboard, copy its public key (the last part of its `appetize.io/app/...` link), and save it as a second secret named `APPETIZE_PUBLIC_KEY`.

After that, each passing build updates Appetize automatically; the link is shown on the build's summary page.

## Test site

The same screens are published to **https://lsims6.github.io/lift-log/** whenever `LiftLog/Web` changes (workflow: *Publish test site*). There, the log saves in that browser only; it's separate from the app on the phone. Pages must be set to **Settings → Pages → Source: GitHub Actions**.
