# Instructions

## What you need

- macOS 14 or later
- Xcode 16 or later (for the Swift toolchain)
- An Anthropic API key from [console.anthropic.com](https://console.anthropic.com)

## Build

```bash
./scripts/build-app.sh
```

This makes `build/Figure Out Your Type.app`. Drag it to Applications if you like.

To run straight from source instead: `swift run`.

## Set up

1. Open the app and press **⌘,** to open Settings.
2. Paste your Anthropic API key and click **Save**. It's stored in your Mac's Keychain.
   (If no key is saved, the app uses the `ANTHROPIC_API_KEY` environment variable.)

## Use

1. **Add photos.** Paste (⌘V), drag them in from Finder, Photos or a browser, or click **Add Photos**.
   Each photo starts a new person.
2. **Group photos of the same person.** Drop more photos onto that person's card, or click its **+**.
   Right-click a photo to remove it; the trash icon removes the whole person.
3. **Add notes (optional).** A line about what each person is like ("funny, ambitious, very spiritual")
   makes the emotional and spiritual read much better. Without notes those sections are marked low confidence.
4. Click **Figure Out My Type** (⌘↩). It takes a minute or two.
5. Read your type. **Back to Photos** returns to your cards; **File → Start Over** (⌘N) clears everything.

Photos and notes go to Anthropic's API only when you click Figure Out My Type. Nothing is saved between launches.
The physical read covers only visible features and never labels race, ethnicity, religion, orientation or health.

## Feedback

Click **Feedback** in the bottom-right corner. Entries are saved to
`~/Library/Application Support/Figure Out Your Type/Feedback.md`.

## Test

```bash
swift test
```
