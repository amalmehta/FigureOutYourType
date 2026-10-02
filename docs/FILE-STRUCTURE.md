# File Structure

```
Package.swift                     Swift package: TypeCore library, the app, tests
figure out your type.md           The spec: brief, decisions, changelog
scripts/build-app.sh              Builds and signs "Figure Out Your Type.app" into build/

Sources/TypeCore/                 Everything that isn't UI
  TypeAnalyzer.swift              Builds the Claude request, calls the API, reads the answer, errors
  Report.swift                    The report's shape (TypeReport) and the JSON schema Claude must follow
  Person.swift                    A person = photos + optional note
  ImagePrep.swift                 Shrinks any image to a ≤1568px upright JPEG
  Keychain.swift                  Saves and loads the API key

Sources/FigureOutYourType/        The Mac app (SwiftUI)
  FigureOutYourTypeApp.swift      App entry, main window, Settings, Start Over command
  AppModel.swift                  App state: people, paste/drop/import, running the analysis
  ContentView.swift               Main window: start screen, people grid, toolbar, progress, Feedback tab
  PersonCard.swift                One person's photos and note
  ReportView.swift                The finished "your type" screen
  SettingsView.swift              API key entry
  FeedbackView.swift              Feedback sheet, saved to Feedback.md

Tests/TypeCoreTests/              Unit tests for image prep, request building and response parsing
docs/                             Instructions, this file, README images
```
