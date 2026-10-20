# Lift Log

A workout and calorie tracker for iPhone. Everything is saved in a file on the phone. Nothing goes over the internet unless you add an optional API key for food estimates.

## What's here

- `LiftLog/Web/index.html`: the whole app screen (workouts, per-set logging, progressive overload, finish & lock, exercise swaps within each muscle group, cardio before and after every workout (stair climber by default, with minutes, level and floors), optional body-weight tracking, a Food tab for calorie tracking, progress charts, history, CSV import/export). Open it in any browser to try it out; there it saves to the browser instead of the phone.
- `LiftLog/LiftLogApp.swift`: the small iPhone shell that shows the page and saves the log to `Documents/lift-log.json` (with a backup copy).
- `LiftLogUITests/`: an automatic test on a simulated iPhone: logs a set, closes the app, reopens it, and checks the set is still there.
- `project.yml`: the Xcode project definition (the build generates the `.xcodeproj` from it with XcodeGen).
- `.github/workflows/build.yml`: builds and tests on a cloud Mac on every push.

## Getting the app

1. Open the **Actions** tab and click the latest **Build Lift Log** run.
2. Check that it has a green check mark, then download **LiftLog-ipa** under *Artifacts* and unzip it to get `LiftLog.ipa`.
3. The **screenshots** artifact shows the app running on a simulated iPhone.
4. Install `LiftLog.ipa` with AltStore: **My Apps → + →** pick the file.

## Layout

The bar along the bottom switches between **Workout** and **Food**. The tabs up top switch views inside each one: Workout has Today, Progress and History; Food has Today and History (daily totals vs your target, a 14-day chart, and every day's meals). The app reopens in the section you used last.

## Food & calories

The **Food** tab tracks calories against a daily target range (2,500–3,000 to start; change it under *Calorie target & estimate settings*). It's free and works offline.

- **Menu:** search ("biscuit", "3 finger", "footlong") or pick a restaurant, then tap foods to build the meal and **Add**. The menu lives in `LiftLog/Web/menu.js` (Chick-fil-A, Raising Cane's, McDonald's, Subway, Firehouse Subs, with sources noted at the top). Edit it and push to add or fix foods.
- **My foods:** anything not on the menu, tap **Enter it myself**, type the calories, and **☆ Save to My foods** so it shows up in search next time.
- **Recent** chips re-log a meal you've had before in one tap.
- **Optional:** with an Anthropic API key (platform.claude.com, billed per use, about $0.0003 an estimate) a box appears for describing food in your own words. The key is kept in the iPhone's Keychain.
- Food shows on the History tab and goes into CSV exports (Set column "Food 1", "Food 2"…, with Calories, Protein and Meal columns). My foods are saved with the log.

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

## TestFlight (Apple Developer account)

With these four repository secrets set (Settings → Secrets and variables → Actions), every build that passes its test is signed and uploaded to TestFlight:

- `ASC_KEY_ID`, `ASC_ISSUER_ID`: from App Store Connect → Users and Access → Integrations → App Store Connect API
- `ASC_KEY_P8`: the full text of the downloaded `AuthKey_….p8` file
- `APPLE_TEAM_ID`: from developer.apple.com/account → Membership details

Install the **TestFlight** app on the iPhone, add yourself to an internal testing group in App Store Connect, and Lift Log shows up there. TestFlight builds expire after 90 days; any push (or **Run workflow** on the Actions tab) makes a fresh one.
