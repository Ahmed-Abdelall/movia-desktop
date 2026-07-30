# Update system

Movia checks the public GitHub Releases API for
`Ahmed-Abdelall/movia-desktop`. Stable checks ignore drafts and prereleases,
compare numeric semantic versions, and accept only
`Movia-Desktop-Setup-{version}.exe` from the repository's HTTPS release path.

Checks are asynchronous. Automatic checks are preference-controlled and limited
to once per 24 hours. Downloads go to the per-user temporary `Movia\updates`
cache. If a matching checksum asset exists, Movia calculates SHA-256 and deletes
and refuses mismatched installers.

Portable users should open the release page and replace their portable folder
manually after closing Movia.
