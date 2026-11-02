# Signing

Builds sign with one stored **Apple Distribution** certificate (expires 2027-11-02) so Apple doesn't make a new
certificate every run.

- The certificate and its private key live only in the GitHub secrets `SIGNING_P12` and `SIGNING_P12_PASSWORD`.
- `LiftLog_AppStore.mobileprovision` is the matching App Store profile ("Lift Log App Store CI"). It isn't secret.
- If those secrets are removed, builds go back to letting Xcode make a fresh certificate each run.
- Before November 2027: make a new certificate and profile, then replace the secrets and this profile.
