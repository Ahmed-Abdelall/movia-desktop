# Update system

Movia checks the public GitHub Releases API for
`Ahmed-Abdelall/movia-desktop`. Stable checks ignore drafts and prereleases,
compare numeric semantic versions, and accept the deployment-mode-specific
installer or Portable Installed ZIP from the repository's HTTPS release path.

Checks are asynchronous. Automatic checks are preference-controlled and limited
to once per 24 hours. Downloads go to the per-user temporary `Movia\updates`
cache. If a matching checksum asset exists, Movia calculates SHA-256 and deletes
and refuses mismatched installers.

Portable Installed updates close the main Movia process, preserve AppData,
replace application files, remove obsolete companion shortcuts/startup entries,
and relaunch only the main window. Standalone portable users update manually.
