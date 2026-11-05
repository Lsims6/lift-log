# Lift Log

A workout and calorie tracker for iPhone. Everything is saved in a file on the phone, and food estimates run on the phone. The only thing the app fetches online is newer versions of its own screens (see Live updates); nothing from the log is ever sent.

## What's here

- `LiftLog/Web/index.html`: the whole app screen (workouts, per-set logging, progressive overload, finish & lock, exercise swaps within each muscle group, cardio before and after every workout (stair climber by default, with minutes, level and floors), optional body-weight tracking, a Food tab for calorie tracking, progress charts, history, CSV import/export). Open it in any browser to try it out; there it saves to the browser instead of the phone.
- `LiftLog/Web/cues.js`: the starting mind-muscle and form cues for each built-in exercise's permanent note.
- `LiftLog/LiftLogApp.swift`: the small iPhone shell that shows the page and saves the log to `Documents/lift-log.json` (with a backup copy).
- `LiftLog/AppShell.swift`: Apple's tab bar (Liquid Glass on iOS 26) for Workout | Food, around the page.
- `LiftLog/LiveWeb.swift`: live updates of the page (below).
- `scripts/web-version.py`: writes `version.json` (commit, time, file checksums) for live updates.
- `LiftLogUITests/`: an automatic test on a simulated iPhone: logs a set, closes the app, reopens it, and checks the set is still there.
- `project.yml`: the Xcode project definition (the build generates the `.xcodeproj` from it with XcodeGen).
- `.github/workflows/build.yml`: builds on a cloud Mac on every push, uploads to TestFlight, then runs the simulator test.

## Getting the app

Every push to `main` builds the app and uploads it to TestFlight (see TestFlight below); it's there about 4 minutes after the push, plus Apple's processing time. The simulator test runs right after the upload, and the run turns red if it fails. The **screenshots** artifact shows the app running on a simulated iPhone.

## Live updates

Most changes are only to `LiftLog/Web`, and those don't need a TestFlight build. The *Publish test site* workflow puts the page on GitHub Pages with a `version.json`. When the app opens or comes back to the front, it checks that file, downloads a newer page, verifies every file's checksum and keeps it in Application Support. A **New version ready · Reload** bar appears; otherwise the new page shows the next time the app comes back to the front. Settings shows which page is running.

- The log lives in `Documents`, separate from the page, so a page swap never touches it.
- A downloaded page is only used if it's newer than the one built into the app and works with this app: `<meta name="liftlog-min-native">` in `index.html` must be at most `NATIVE_API` in `LiveWeb.swift`. Bump both when the page starts needing something new from the Swift side, and that page then waits for the matching TestFlight build.
- If a downloaded page doesn't report that it started within 12 seconds, the app marks it bad and goes back to the built-in page.
- Changes to the Swift files still need a TestFlight build.

## Workout plan

Your workouts, their exercises and which day each one falls on are all editable: **Settings → Workout plan → Edit workouts & schedule**. You can rename, add or delete workouts; add, remove or reorder exercises; change set counts; pick any workout (or a rest day) for each day of the week; and make your own exercises (name, muscle group, compound / isolation / cardio). A new install opens a setup screen with starter plans (5-day split, Push/Pull/Legs, Upper/Lower, Full body, or start from scratch). Logs made before plans were editable keep the original 5-day split with its starting weights.

## Workout extras

- **Lunch-break cardio:** a card above the workout every day (Walk by default, or any cardio machine). It stays editable after the workout is locked, counts toward cardio minutes, and a lunch-only day isn't counted as a gym day.
- **Notes:** every exercise and cardio card has two. The *permanent note* is one per exercise, for seat settings and cues: it shows every time that exercise comes up, on any day and in any plan, and you edit that same note. Built-in exercises start with where to feel the lift and one or two form points; a note you already had stays on top, and text you edit or clear doesn't come back. The *note for today* belongs to that date; the next time, the card shows it as *Last note*. On cardio, the before, after and lunch cards each keep their own daily note.
- **Skip today:** each exercise has a *Skip today* button that hides it for that date only. The plan doesn't change; tap *Undo* to bring it back. If sets were already logged, it asks for a second tap before clearing them.

## Layout

The gear at the top right opens **Settings**: workout plan, calorie target (TDEE calculator), macro targets, weight goal (shown on weigh-ins and the Progress chart, with a rough time to reach it), food estimate status, CSV export/import, privacy policy, erase all data, and the app version.

The bar along the bottom switches between **Workout** and **Food**. The tabs up top switch views inside each one: Workout has Today, Progress and History; Food has Today and History (daily totals vs your target, a 14-day chart, and every day's meals). The app reopens in the section you used last.

## Food & calories

The **Food** tab tracks calories against a daily target range. In **Settings → Calorie target**, enter sex, age, height, weight and activity: the app works out your BMR (Mifflin-St Jeor) and TDEE and sets the range from extreme loss (TDEE − 1,000, about 2 lb/week) to mild loss (TDEE − 250, about ½ lb/week), never below 1,500 (men) / 1,200 (women). Leave weight blank and it follows your latest weigh-in. You can still type your own range. It's free and works offline.

*Add food* shows one way of adding at a time, on tabs: Menu, Quick add, Paste and, with Apple Intelligence, Describe. The tab you used last comes back.

- **Macros:** protein, carbs and fat are tracked with the calories, each with a small bar and target range on Food › Today. The ranges apply a split from tdeecalculator.net to the low and high ends of your calorie target: Moderate carb (30% protein, 35% fat, 35% carbs), Lower carb (40/40/20) or Higher carb (30/20/50), chosen in **Settings → Macro targets**. You can also set your own protein goal or range there; the remaining calories then go to carbs and fat in the split's proportions. Leave it blank to use the split. Food logged before 3.01 has no carbs or fat, and the page says how many items a day's totals leave out.
- **Quick add:** type a calorie number and, if you like, what it was and its macros. It goes straight onto the day, no menu needed.
- **Menu:** search ("biscuit", "3 finger", "footlong") or pick a restaurant, then tap foods to build the meal and **Add**. The menu lives in `LiftLog/Web/menu.js` (Chick-fil-A, Raising Cane's, McDonald's, Subway, Firehouse Subs, with sources noted at the top). Edit it and push to add or fix foods.
- **My foods:** anything not on the menu, tap **Enter it myself**, type the calories, and **☆ Save to My foods** so it shows up in search next time.
- **Recent** chips re-log a meal you've had before in one tap.
- **Estimates:** on an iPhone with Apple Intelligence (iPhone 15 Pro or newer, iOS 26+, turned on in Settings), a box appears for describing food in your own words. Apple's on-device model splits it into items with calories and macros, using matching menu lines as hints. Free, offline, and nothing leaves the phone. Without Apple Intelligence the box stays hidden.
- Food shows on the History tab and goes into CSV exports (Set column "Food 1", "Food 2"…, with Calories, Protein, Meal, Carbs and Fat columns). My foods are saved with the log.

## Moving data

- **Export CSV** (Settings) opens the share sheet: save to Files, AirDrop, or email.
- **Import CSV** reads a file exported from Lift Log (the web version or this app). Past days come in as finished workouts.
- Body weight is exported as rows with the exercise "Body weight" and the weight in the Weight column, and comes back in on import.

Your log lives inside the app. Updates (TestFlight or live) keep your data, but deleting the app deletes the log, so export a CSV now and then as a backup.

## Test site

The same screens are published to **https://lsims6.github.io/lift-log/** whenever `LiftLog/Web` changes (workflow: *Publish test site*). There, the log saves in that browser only; it's separate from the app on the phone. Pages must be set to **Settings → Pages → Source: GitHub Actions**.

## TestFlight (Apple Developer account)

With these four repository secrets set (Settings → Secrets and variables → Actions), every build is signed and uploaded to TestFlight:

- `ASC_KEY_ID`, `ASC_ISSUER_ID`: from App Store Connect → Users and Access → Integrations → App Store Connect API
- `ASC_KEY_P8`: the full text of the downloaded `AuthKey_….p8` file
- `APPLE_TEAM_ID`: from developer.apple.com/account → Membership details

Install the **TestFlight** app on the iPhone, add yourself to an internal testing group in App Store Connect, and Lift Log shows up there. TestFlight builds expire after 90 days; any push (or **Run workflow** on the Actions tab) makes a fresh one.

## Privacy policy

`LiftLog/Web/privacy.html`, published at **https://lsims6.github.io/lift-log/privacy.html** with the test site. Use that address for the App Store listing's privacy policy URL. Settings links to it.
