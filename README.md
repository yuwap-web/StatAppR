# StatAppR

![StatAppR Icon](icon.png)

**StatAppR** is a macOS statistical analysis application powered by **R**.  
It provides a simple graphical interface for performing common statistical analyses such as regression, survival analysis, and causal inference workflows.

StatAppR is designed for researchers, clinicians, and analysts who want to run statistical methods without writing R scripts manually.

---

## Download

Download the latest version from **GitHub Releases**:

➡ Download from: https://github.com/yourusername/StatAppR/releases

---

## Installation

1. Download `StatAppR.dmg`
2. Open the DMG file
3. Drag **StatAppR.app** into the **Applications** folder
4. Launch **StatAppR** from Applications

---

## Security

StatAppR is:

- **Signed with Apple Developer ID**
- **Notarized by Apple**

You can verify the signature using:

```bash
spctl -a -vv /Applications/StatAppR.app
System Requirements

macOS 15.6 or later

R 3.5.0 or later

Internet connection for first-time setup

R Installation

StatAppR uses the locally installed Rscript executable.

If R is not detected when the application starts, StatAppR will provide step-by-step instructions within the application on how to install R.

StatAppR checks common Rscript locations including:

/opt/homebrew/bin/Rscript
/usr/local/bin/Rscript
/usr/bin/Rscript

For most users, installing R via Homebrew is recommended.

Example installation:

brew install r
Features

Linear regression

Logistic regression

Cox proportional hazards regression

Kaplan–Meier survival analysis

Propensity score analysis

Inverse Probability of Treatment Weighting (IPTW)

Causal inference workflows

R-based statistical engine

Native macOS interface

Verification

To verify the application signature:

spctl -a -vv /Applications/StatAppR.app

Expected output:

source=Notarized Developer ID
License

MIT License

Author

Tetsuhiro Yasuda

Contributing

Issues and feature requests are welcome.

Please open an issue on GitHub if you encounter problems or have suggestions.
<img width="1024" height="1024" alt="icon" src="https://github.com/user-attachments/assets/4a7ed1e5-1b28-4e7d-8a2f-1c7d1d8f5985" />
