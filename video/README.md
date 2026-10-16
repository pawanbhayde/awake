# Awake ☕️ Launch Video (HyperFrames)

This directory contains the full 1920x1080 motion launch video for **Awake**, built with [HyperFrames](https://hyperframes.heygen.com).

## Output File
- Master Video: [`renders/awake-launch.mp4`](renders/awake-launch.mp4) (28.0s, 30fps, 3.5MB H.264)

## Project Structure
- `index.html`: Master timeline mounting 5 modular sub-compositions.
- `compositions/scene1-intro.html`: Hook & 3D Retina icon reveal (*"Your Mac. Wide Awake."*).
- `compositions/scene2-menubar.html`: macOS menu bar & interactive timer popover.
- `compositions/scene3-clamshell.html`: Clamshell mode & developer/AI compute cards.
- `compositions/scene4-terminal.html`: Battery cutoff safeguards & CLI shell automation.
- `compositions/scene5-outro.html`: 100% Free & Open Source outro CTA.
- `assets/`: 1024x1024 Retina App Icon and background textures.

## Commands

```bash
# Preview in browser
npx hyperframes preview

# Run lint & WCAG AA contrast check
npx hyperframes check

# Render to MP4
npx hyperframes render --output renders/awake-launch.mp4 --quality looks
```
