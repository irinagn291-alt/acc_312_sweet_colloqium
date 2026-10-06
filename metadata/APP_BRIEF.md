<!-- gf-brief source=ddd7c9783828778506a8ec0707124539c93c5f2e31ce66d50717a7ad1545feab written=2026-10-06T21:02:38+03:00 -->
# Sweet Colloqium
## What it is
Sweet Colloqium is a private week habit app for one habit at a time. You close today first. If a scheduled day already slipped, this week’s one lost beat can mend that silent day so the miss still counts. It is for people who want a week that still holds after a miss, not a streak that zeros when one day is left open.

## Launch and onboarding
The Home Screen label is Sweet Colloqium. The app is light only. There is no tab bar.

On a device that has never finished onboarding, a cold launch shows the system launch screen (no wordmark or buttons), then a short wait. A spinner may appear if that wait lasts. Then onboarding, three pages, with “Skip” at the top right on every page.

1. Page 1. Headline “The week still holds.” Body “Close today first. A miss does not have to zero the week.” A field with placeholder “Habit name”, already filled with “Daily lap” unless a habit already exists. Bottom button “Continue” moves to page 2. The field is optional.
2. Page 2. Headline “Tap today's ring.” Body “One press closes today and fills that day's ring.” Bottom button “Continue” moves to page 3.
3. Page 3. Headline “Mend a day that slipped.” Body “Tap a silent past day to spend this week's lost beat. Tomorrow cannot take it.” Bottom button “Close the first ring” ends onboarding and opens Rings.

“Skip” ends onboarding from any page and opens Rings. Skip always seats the habit as “Daily lap” when there is no habit yet. It does not rename an existing habit. Finishing page 3 seats or renames the habit to whatever is in “Habit name”; if that field is blank, the habit is “Daily lap”.

Default scheduled weekdays after Skip or a first finish are Monday through Friday, plus today, plus yesterday, using the device calendar.

A later launch, after onboarding is done, skips these pages and opens Rings with the saved habit and marks. On Simulator, a first launch may skip onboarding and open a filled Rings week instead. See Starter content.

## Screens
There are no tabs. Rings stays on screen. Dashboard, Lost beat, and Settings arrive as full-height sheets with a drag indicator. Dismissing a sheet returns to Rings.

### Rings
Home. No navigation title. Top left reads “This week”. Top right has three icon-only controls: “Dashboard” (opens the Dashboard sheet), “Lost beat” (opens the Lost beat sheet), and “Settings” (opens the Settings sheet).

When there is no habit, the page is “No habit yet.” then “Close the first ring.” The bottom button is “Close the first ring”. That tap seats “Daily lap” with the default weekdays and shows the filled Rings layout. It does not close today.

When a habit exists:

- The habit name is the masthead (for example “Daily lap” or “Quiet lap”).
- A job line under a hairline, one of:
  - “Tap Close to close today's ring.”
  - “Today is rest. A silent day can take this week's lost beat.”
  - “Today is closed. Tap a silent past day to mend it.”
  - “Today is closed. This week still holds a lost beat.”
  - “Today is closed. This week's lost beat is spent.”
- A stat line: a locale-formatted “X of Y”, then “this week”, then “Streak N”.
- Optional notice or save lines, each with “Try again”:
  - “Restored from a backup on this device.”
  - “The week could not be read. Try again, or close a first ring.”
  - “The last save did not finish. Try again.”
  - Or a refuse line from Close or Mend (listed under Behaviours).
- Primary button “Close”. Spoken name “Close today's ring”. Enabled only when today is a scheduled day that is still Open. A successful tap closes today, marks that ring Closed, and briefly flashes a success stamp with no text.
- A row of seven day rings. Each ring shows a locale weekday letter and a state word: “Closed”, “Mended”, “Open”, “Soon”, or “Rest”. Today’s ring is larger. Spoken name is the locale weekday-and-date plus that state word. Spoken hints: “Closes today.”, “Spends this week's lost beat.”, “Future days refuse.”, or “That day is rest.” Tapping today runs Close. Tapping any other day tries to mend it.
- “Mend target”. If a silent past scheduled day can take the lost beat, it shows that day’s locale weekday-and-date and “Tap a silent past day. Future days refuse.” Tap mends that day. If the lost beat is still held but no silent day exists, it shows “No silent scheduled day yet. Miss one, then tap that day.” Tap opens Lost beat. If the lost beat is spent, it shows “A second mend this week is refused.” Tap opens Lost beat. Spoken name is “Mend that day” when a target exists, otherwise “Lost beat”.
- “This week”: one row per day of the current week. Each row is the locale weekday-and-date and the same state word as the ring (“Closed”, “Mended”, “Open”, “Soon”, or “Rest”). Tapping today runs Close. Tapping another day tries to mend it.
- A day-chain strip (spoken name “Day chain”) with the same seven days. Taps match the rings.
- Bottom strip “Lost beat held” or “Lost beat spent”. Held uses “Tap a silent past day. Future days refuse.” Spent uses “A second mend this week is refused.” Tap opens Lost beat.

### Dashboard
Sheet title “Dashboard”. Trailing close control spoken as “Close dashboard”.

Empty, no habit: “No habit yet.” then “Close the first ring, then the week will gather here.” Bottom button “Close today's ring” dismisses the sheet. It does not close a day.

Empty, habit exists but nothing closed or mended yet: “No closed days yet.” then “Close today's ring. Marks will land here.” Bottom button “Close today's ring” dismisses the sheet.

Populated:

- Hero figure “X of Y”, then “closed of scheduled”, then “Streak N”, then one hue line:
  - “Ended weeks: sparse. This week does not color until it ends.”
  - “Ended weeks: steady. This week does not color until it ends.”
  - “Ended weeks: solid. This week does not color until it ends.”
- Optional “Restored from a backup on this device.” or “The week could not be read. Try again.” or “The last save did not finish. Try again.”, each with “Try again”.
- Section “Closed days”. Each row is a locale weekday-and-date, a subtitle “Closed that day.” or “Mended miss. Still counts.”, a mark “Closed” or “Mended”, and a when label “Today”, “Yesterday”, or the locale weekday-and-date. Rows are not tappable. The list grows as days are closed or mended.

### Lost beat
Sheet title “Lost beat”. Trailing close control spoken as “Close lost beat”.

Empty, no habit: “No habit yet.” then “Name a habit first. Then a silent day can take this week's lost beat.” Bottom button “Close the first ring” dismisses the sheet.

When a habit exists:

- “Mend a silent day.”
- “Tap an empty past day. Future days refuse. A second mend this week is refused.”
- Status card: “This week still holds a lost beat.” or “This week already spent its lost beat.”
- If there is no silent past scheduled day and the lost beat is held: “No silent scheduled day yet. Miss one, then tap that day.”
- If there is no silent past scheduled day and the lost beat is spent: “Wait for the week to turn. An unused lost beat drops then.”
- If silent days exist, each is a row with that day’s locale weekday-and-date and the button “Mend”. Spoken name “Mend” plus that date. A successful Mend spends this week’s lost beat, marks that day Mended, and the miss still counts. Mend rows are disabled while a mend is in flight or when the lost beat is spent.
- Optional refuse or save line with “Try again”, same wording as Rings where it applies.
- “Back to Rings” dismisses the sheet.

### Settings
Sheet title “Settings”. Trailing close control spoken as “Close settings”. Closing the sheet, or leaving the screen, saves the habit if the name is not blank and at least one weekday is selected.

When there is no habit, a banner reads “No habit yet. Name it, pick the weekdays, then save.”

Controls, in order:

- Label “Habit”. Field placeholder “Habit name”.
- Label “Scheduled weekdays”. Seven chips in the device week order. Each chip shows the first two letters of the locale short weekday name, a checkmark when on and a circle when off. Spoken name is the locale short weekday. Spoken value “Scheduled” or “Off”. Tap toggles that day. The last remaining scheduled day cannot be turned off.
- Optional “The last save did not finish. Try again.” with “Try again”.
- “Save habit”. Writes the name and weekdays, keeps onboarding finished, and stays on Settings. Disabled when the name is only spaces or no weekday is selected. Days left off become Rest on Rings. Marks already written on days that stay scheduled are kept.
- “Contact Stackfreed”. Opens the support page. The address “https://stackfreed-week.pro/contact-us” is printed under the button.
- “Re-run onboarding”. Saves pending habit edits if they are valid, dismisses Settings, and returns to the three onboarding pages. The existing habit and marks remain. Skip keeps the current name. “Close the first ring” on page 3 can rename the habit.
- “Reset all data”. Opens a confirmation titled “Reset all local marks?” with body “Closed days, mended days, and the habit leave this device.” Buttons: “Reset all data” (destroys the habit and every mark on this device, then returns to onboarding) and “Keep marks” (cancels).

On a wide iPad, a side column titled “What Save habit will change” also shows the draft name, “Week rings stay on the home screen. Days you leave off become rest.”, a live copy of the week rings, another “Scheduled weekdays” grid, and “N weekdays stay scheduled after Save habit.” Those rings can Close today or Mend a silent past day the same way Rings does.

## Features
- One habit, named by the user.
- Rings for the current week, with Close for today.
- Scheduled weekdays versus Rest days.
- One lost beat per week, held or spent.
- Mend a silent past scheduled day so a “Mended miss. Still counts.”
- Future days stay “Soon” and refuse Mend.
- A second Mend in the same week is refused.
- An unused lost beat drops when the week turns. The new week starts with the lost beat held again.
- Dashboard list of closed and mended days, “X of Y” “closed of scheduled”, and “Streak N”.
- Ended-week read as sparse, steady, or solid. “This week does not color until it ends.”
- Settings to save the habit and weekdays, re-run onboarding, reset all data, and Contact Stackfreed.
- Everything stays on this device.

## Behaviours that can look like bugs
- “Close” is dimmed when today is already Closed or today is Rest. It is not broken. Wait for a scheduled today that is still Open, or add today under “Scheduled weekdays” and tap “Save habit”. A refused Close can show “Today is already closed.” or “Today is rest. There is no ring to close.”
- Tapping a future day does nothing useful and can show “Future days stay closed until they arrive.” Those rings read “Soon”. Wait until that day arrives.
- Tapping today on Mend (the day chain, a week row, or a ring that is not using Close) shows “Close today with Close. Mend is for a day that slipped.” Use “Close” instead.
- Tapping a Rest day can show “That day is rest. Mend a scheduled silent day.” Schedule that weekday, or mend a scheduled silent day.
- Tapping a day that is already Closed or Mended can show “That day is already closed.”
- After this week’s lost beat is spent, Mend is refused and can show “This week already spent its lost beat.” Rings reads “Lost beat spent” and “A second mend this week is refused.” Wait for the week to turn.
- “No silent scheduled day yet. Miss one, then tap that day.” appears when the lost beat is still held and every past scheduled day is already Closed or Mended. Leave a scheduled day Open, then tap that day. After a first Skip or finish, yesterday is often already a silent scheduled day, so Mend can be available immediately even though the line talks about missing one.
- On Lost beat, after the beat is spent, the card can show both “This week already spent its lost beat.” and “Wait for the week to turn. An unused lost beat drops then.” The week turn is the way forward.
- Empty Dashboard “Close today's ring” and empty Lost beat “Close the first ring” only dismiss the sheet. Close the day on Rings with “Close”.
- Empty Rings “Close the first ring” only creates “Daily lap”. Tap “Close” after that to close today.
- “Save habit” stays disabled until “Habit name” has text and at least one weekday is on. The last scheduled weekday will not turn off. Select another day first.
- Onboarding page is not remembered mid-flow. Killing the app on page 2 or 3 starts again at page 1 with “Skip” still available.
- “Re-run onboarding” and “Reset all data” both return to the three pages on purpose. Reset also clears the habit and marks.
- “Closed days” starts empty (“No closed days yet.”) and grows after Close or Mend. Reset clears it.
- “X of Y” “this week” ignores future Open days, so the second number is scheduled days that have already arrived, not always seven. “Streak N” counts Closed and Mended scheduled days backward and stops at a miss. Today still Open does not break the streak.
- The Dashboard hue line does not change during the current week. After the week ends, ended weeks can read sparse, steady, or solid.
- “The last save did not finish. Try again.” and “The week could not be read. Try again.” stay until “Try again” succeeds or a later save works. “Restored from a backup on this device.” is an informational restore, not a failed launch.
- Skip ignores a typed name and seats “Daily lap” when there is no habit yet. Use “Continue” through “Close the first ring”, or rename under Settings, to keep a custom name.

## Starter content and resume
On a physical device there is no sample week. The first habit appears only after Skip, “Close the first ring” on onboarding page 3, empty-home “Close the first ring”, or Settings “Save habit”. Skip and empty-home use “Daily lap”. Finishing onboarding uses the typed name, or “Daily lap” if that field is blank.

On Simulator, a first launch can already be finished: habit “Quiet lap”, onboarding already done, a prior week of Closed days plus one Mended day, some past days this week already Closed, the earliest past scheduled day this week left Open so it can take the lost beat, and today still Open so “Close” is enabled.

Closed days, mended days, the habit name, scheduled weekdays, and whether the lost beat is held persist across launches and return you to Rings. There is no draft of a Close. An unfinished onboarding page does not resume; it starts at page 1. Settings name and weekday edits save when the sheet closes if they are valid.

## Permissions
None. The app never asks for camera, photos, microphone, location, notifications, or tracking.

## Absent
Genuinely absent: login or accounts, in-app purchase, ads, analytics, user-generated content, account deletion flow, App Tracking Transparency prompt.

## Data and support
Data stays on this device. Reset copy says “Closed days, mended days, and the habit leave this device.”

The on-screen control is “Contact Stackfreed”. It opens the support page. The printed address under the button is “https://stackfreed-week.pro/contact-us”.

## Scanning and health
None. The app does not scan barcodes or QR codes. It does not show health, medical, or product-health information and has no citations.

## Platform
No region lock. Copy is English. Week start, weekday names, dates, and numbers follow the device calendar and locale.

Portrait only on iPhone and iPad. Light appearance only. iPhone and iPad. Minimum iOS 17.0.

## Category
Health & Fitness.
