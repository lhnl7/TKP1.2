# tkp (Basic A) - TikTok-style local player (Guaranteed buildable)

This repo is a minimal, clean iOS project intended to be uploaded to GitHub as-is.
It includes:
- SwiftUI app that hosts a UIKit PlayerViewController.
- Player lets you pick videos from Photos (PHPicker) and plays them in a vertical full-screen feed.
- A GitHub Actions workflow that archives and creates an unsigned IPA (no Apple certs required).

How to use:
1. Upload all files (do NOT upload the zip itself) to your GitHub repository root.
2. Ensure the repo default branch is 'main' or adjust workflow triggers.
3. Run the workflow from Actions -> Build IPA.
4. Download the artifact 'tkp-ipa'.

Notes:
- IPA is unsigned. Install via AltStore / Sideloadly.
- iOS 15+ for PHPicker APIs.
