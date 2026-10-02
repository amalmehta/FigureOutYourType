PROJECT NAME: figure out your type

META-INSTRUCTIONS:

<Read it all before acting. Ask about anything unclear, contradictory or
 underspecified — before starting and mid-build. Ask in the question widget
 (AskUserQuestion): related questions batched, concrete options, your
 recommendation first. Plain text only if the widget isn't available.>

<Don't expand scope. Anything not listed here is a proposal, including changes
 to this file — propose it, don't do it.>

<Prefer doing over describing: run the code, write the files, test it.>

<Always in scope, no proposal needed: when it goes on GitHub, a README that is
 easy to read at a glance — a line on what it is, then clear visuals
 (screenshots, a diagram or a chart), then links. Everything else goes in
 linked files: docs/INSTRUCTIONS.md (setup, run, use) and
 docs/FILE-STRUCTURE.md (what's where). Also a small unobtrusive feedback tab
 if what you're building is an application rather than a script.>

<If what you're building is an application, build it as a Mac app first; the
 website comes after, as its own step.>

<Name things the way a person would say them — "Goal Tracker", not
 goal_tracker — for the app, its windows, titles, files people open, repo
 descriptions and README headings. When you create the GitHub repo, name it
 with no "_" or "-": one word or joined words, e.g. GoalTracker.>

<Finish by listing every deliverable: path, what it is, how to check it works.>

<Git rules (no Claude attribution, never commit .claude/) are in
 ~/.claude/CLAUDE.md and apply on their own — nothing to repeat here.>

<Keep the changelog at the bottom current.>

CONTEXT:

paste images of the type of person you’d like to date. can be multiple people

DELIVERABLES:

figure out the persons actual type (physical, emotional, spiritual, etc)

OPEN QUESTIONS / ASSUMPTIONS:

Asked and answered (2026-10-02):
- Analysis: Claude API (claude-opus-5-5) with your own API key, saved in the Mac Keychain.
- Inputs: photos plus an optional note per person (approved addition) so emotional and spiritual type have real input.
- Sensitive traits: physical type covers visible features only — never race, ethnicity, religion, orientation or health.
- Scope now: Mac app. GitHub repo added 2026-10-02 (private, spec included at its current path); no website yet.

Decided without asking:
- Native SwiftUI app built with Swift Package Manager (no Xcode project); scripts/build-app.sh wraps it into "Figure Out Your Type.app" (ad-hoc signed, macOS 14+).
- "etc" in the deliverable became a fourth dimension: Style & Lifestyle. The report also lists what all the people share, who breaks the pattern, and caveats.
- Each pasted/dropped photo starts a new person; drop onto a card or use its + to add more photos of the same person.
- Photos are downscaled to 1568px JPEG before sending. Effort "high", structured JSON output, and server-side refusal fallback ("fallbacks": "default") are on.
- Nothing is saved between launches (photos, notes and reports live only in memory).
- Feedback tab saves to ~/Library/Application Support/Figure Out Your Type/Feedback.md (no server to send it to).
- The ANTHROPIC_API_KEY environment variable is used if no key is saved in Settings.
- Not yet verified: a live API call and the report screen, since no API key was available during the build.

CHANGELOG:

- 2026-10-02 — created
- 2026-09-15 — added meta-instruction: built-out applications include a small feedback tab
- 2026-09-15 — added meta-instruction: no "Claude" attribution in commits, PRs, or branches
- 2026-09-16 — added meta-instruction: always include a README when adding to GitHub
- 2026-09-16 — changed meta-instruction: ask clarifying questions in the question widget
- 2026-09-17 — added meta-instructions: Claude never a contributor; never commit .claude/
- 2026-09-26 — compressed the meta-instructions and every field prompt; git rules moved to the global instruction file
- 2026-09-27 — added meta-instruction: applications are built as a Mac app first, then a website
- 2026-09-28 — folded inputs, instructions, constraints, deliverables and done criteria into one free-form CONTEXT
- 2026-09-28 — changed meta-instruction: a README on GitHub always includes a visual
- 2026-09-28 — added meta-instruction: name things like a person would, never snake_case
- 2026-09-28 — changed meta-instruction: README leads with visuals; instructions live in a linked guide
- 2026-09-28 — changed meta-instruction: README is visuals and links; details in docs/INSTRUCTIONS.md and docs/FILE-STRUCTURE.md
- 2026-09-29 — changed meta-instruction: GitHub repo names have no "_" or "-"
- 2026-10-02 — added a DELIVERABLES field after CONTEXT
- 2026-10-02 — built the Mac app (Figure Out Your Type); filled in OPEN QUESTIONS / ASSUMPTIONS
- 2026-10-02 — put on GitHub as private repo FigureOutYourType with README, docs/INSTRUCTIONS.md and docs/FILE-STRUCTURE.md
