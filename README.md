# Figure Out Your Type

Add photos of people you'd like to date and find out your actual type: physical, emotional, spiritual, and style & lifestyle. Available as a Mac app and a website.

**[Try the website →](https://amalmehta.github.io/FigureOutYourType/)**

![Start screen](docs/images/Start%20Screen.png)

![Sample report](docs/images/Sample%20Report.jpg)

## How it works

```mermaid
flowchart LR
    A["Paste, drop or add photos<br/>(one card per person)"] --> B["Optional note per person<br/>'kind, outdoorsy, into meditation'"]
    B --> C["Figure Out My Type"]
    C --> D["Claude looks for patterns<br/>across everyone"]
    D --> E["Your type"]
    E --> P[Physical]
    E --> Em[Emotional]
    E --> S[Spiritual]
    E --> L[Style & Lifestyle]
    E --> X["What they all share ·<br/>who breaks the pattern"]
```

## Links

- [Website](https://amalmehta.github.io/FigureOutYourType/)
- [Instructions](docs/INSTRUCTIONS.md): setup, run, use
- [File Structure](docs/FILE-STRUCTURE.md): what's where
- [Spec](figure%20out%20your%20type.md): the brief, decisions and changelog
