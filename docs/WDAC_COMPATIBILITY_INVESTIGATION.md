# Movia Desktop WDAC / Smart App Control Compatibility Investigation

Date: 2026-08-01  
Repository: `C:\Users\Ahmed Abdelaal\OneDrive\Documents\Movia\movia-desktop`  
Installed build: `C:\Users\Ahmed Abdelaal\AppData\Local\Programs\Movia`  
Active policy: `VerifiedAndReputableDesktop`, policy ID `27555.1000.240208`, GUID `{0283ac0f-fff1-49ae-ada1-8a933130cad6}`

## Executive finding

Movia Desktop v1.1.0 runs because the exact installed files have already been authorized and cached as reputable by Windows' Verified-and-Reputable application-control path. The installed executable and DLLs are unsigned, have no catalog signature, have no Zone.Identifier, and have no documented Managed Installer `KERNEL.SMARTLOCKER.ORIGINCLAIM`. The sampled installed binaries do carry the internal `$KERNEL.PURGE.ESBCACHE` execution/security cache EA. A fresh launch of installed v1.1.0 produced a responsive Movia window and no Code Integrity block event.

Fresh v1.2.0 files have new, unknown hashes and no cached authorization. Smart App Control is in enforcement mode (`VerifiedAndReputablePolicyState=1`). Code Integrity requests signing/trust level 2, validates the new unsigned files only at level 1, and blocks them with `0xC0E90002`. This is reputation/trust-state behavior, not a path, publisher, catalog, Zone.Identifier, or source-code defect.

The Smart App Control policy was activated on 2026-07-25, before v1.1.0 was installed on 2026-07-30. Installation-before-policy is therefore ruled out.

## Trust mechanism determination

| Candidate | Finding |
|---|---|
| Exact hash rule | No policy rule identifier or explicit hash allow event was found. The clean v1.1 rebuild has different hashes and did not reproduce the installed trust state. |
| Path rule | Ruled out as the cause. v1.2.0 was blocked from the repository, `C:\tmp`, and Explorer. The policy reports Verified-and-Reputable enforcement. |
| Publisher rule | Ruled out. All Movia executables and plugin DLLs are `NotSigned`; no signer certificate exists. |
| ISG / Smart App Control reputation | Confirmed as the effective authorization class. The active policy is `VerifiedAndReputableDesktop`; installed v1.1 files possess execution-security cache EAs, while v1.2 files do not. |
| Managed Installer | Not observed. `KERNEL.SMARTLOCKER.ORIGINCLAIM`, Microsoft's documented Managed Installer/ISG-origin marker, is absent. |
| Catalog | Ruled out. `signtool verify /a /pa /v` reports no signature and cannot verify either generation using a catalog. |
| Zone.Identifier | Ruled out. Neither installed nor fresh binaries have a Zone.Identifier stream. |
| Installed before policy | Ruled out. Event 3099 activated the policy on 2026-07-25; installed-file timestamps are 2026-07-29/30. |

Microsoft documents that Smart App Control permits signed code or code predicted safe by its cloud reputation service, and blocks unknown unsigned code. Microsoft also documents that ISG authorization creates an extended file attribute and that files with an ISG EA run before a new cloud reputation query. See [Application Control and Smart App Control](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/app-control-for-business/appcontrol), [policy rule options and ISG EAs](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/app-control-for-business/design/select-types-of-rules-to-create), and [Managed Installer and ISG troubleshooting](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/app-control-for-business/operations/configure-appcontrol-managed-installer).

`$KERNEL.PURGE.ESBCACHE` is an internal Windows cache EA and is not documented as a stable deployment interface. It must not be copied, forged, or treated as a release mechanism.

## Installed v1.1.0 binary inventory

All entries have no Zone.Identifier, Authenticode status `NotSigned`, and no signer. Blank metadata means the PE file exposes no value.

| File | SHA-256 | File version | Product / Company / Original | Created UTC | Modified UTC |
|---|---|---|---|---|---|
| `dartjni.dll` | `17725DD093BB29C3BAC70DD04491C4AF9E72958FE6756D32EC966AC846B2C4BA` | — | — | 2026-07-30T09:07:44.6752956Z | 2026-07-30T04:07:26Z |
| `desktop_multi_window_plugin.dll` | `37CDEBCB37BD35DB5B4733BB5E1B6F091F6D0B40F28CE05645347F514692A66E` | — | — | 2026-07-30T07:43:43.8942610Z | 2026-07-30T04:07:16Z |
| `file_selector_windows_plugin.dll` | `9BC9B8FE4CB7B278B60AAABF4D00F4702DD4B144D906C6A6D7484EC72C8078DC` | — | — | 2026-07-29T17:23:40.0412772Z | 2026-07-30T04:07:26Z |
| `flutter_windows.dll` | `890B23404E770D3A01A978E6EE8DBEEF9006C85C39A9F5D75E3F91E5BCF3BB80` | — | — | 2026-07-29T17:23:40.0492398Z | 2026-07-23T12:02:44Z |
| `movia_desktop.exe` | `02FAFD518F151161055247BEA40CC4E0880524F379E90D368DF5A37D28C0C853` | `1.1.0+2` | Movia Desktop / Ahmed Abdelaal / movia_desktop.exe | 2026-07-29T17:23:40.5191083Z | 2026-07-30T04:07:50Z |
| `screen_retriever_windows_plugin.dll` | `3A868F9DD63C3136BA4E5725F0FD5F18F4B7657F43693A526DEC737BB2972721` | — | — | 2026-07-30T07:43:44.4683404Z | 2026-07-30T04:07:32Z |
| `sqlite3.dll` | `858141A2826F53E8374CB07DE2638E0F1AC944F49B897DD558FEBA5597E86D1C` | — | — | 2026-07-29T17:23:40.5225514Z | 2026-07-30T04:05:40Z |
| `unins000.exe` | `246D220F12417BD60CCB5AFBC4B79EB92E9BF6A64FAFAAAFE2F45731C3C436D0` | `51.1054.0.0` | Movia Desktop / Ahmed Abdelaal / — | 2026-07-30T09:07:44.6550720Z | 2026-07-30T09:07:19.2551496Z |
| `url_launcher_windows_plugin.dll` | `E700AEF5F31DBB6295528D90CD9A77779751F0C61E322DB6E2A3A8305D0A1F1F` | — | — | 2026-07-30T07:43:44.5253239Z | 2026-07-30T04:07:38Z |
| `window_manager_plugin.dll` | `2F9BB7B01AD9B0B0CFB6A18AC52E63E9CE583FC1F037A29612816F6AFF249205` | — | — | 2026-07-30T07:43:44.5283303Z | 2026-07-30T04:07:44Z |

## Fresh v1.2.0 binary inventory

All entries have no Zone.Identifier, Authenticode status `NotSigned`, no signer, and no product metadata except the main executable.

| File | SHA-256 | File version | Product / Company / Original | Created UTC | Modified UTC |
|---|---|---|---|---|---|
| `desktop_multi_window_plugin.dll` | `ADD4B04163A584DA28A12CBC382C6FD4EBECCED02EF70E02205A098035E7D32D` | — | — | 2026-08-01T08:09:43.8180292Z | 2026-08-01T08:09:19.0649380Z |
| `file_selector_windows_plugin.dll` | `FF0D47EBFFF49956D809991E0C1EA831FCEF873D203D6D6309D519D58CF82505` | — | — | 2026-08-01T08:09:43.8259536Z | 2026-08-01T08:09:25.4437964Z |
| `flutter_windows.dll` | `890B23404E770D3A01A978E6EE8DBEEF9006C85C39A9F5D75E3F91E5BCF3BB80` | — | — | 2026-08-01T08:09:43.8786400Z | 2026-07-23T12:02:44Z |
| `movia_desktop.exe` | `33340EFE2ECB17BD9931C059EF2926DD63DC00EFCF8AACE3682E564437F91849` | `1.2.0+3` | Movia Desktop / Ahmed Abdelaal / movia_desktop.exe | 2026-08-01T08:09:43.8926397Z | 2026-08-01T08:09:42.7069421Z |
| `screen_retriever_windows_plugin.dll` | `CC3BD1FAAAD134D744576F8978300035F258F78F1CDD3DE177B5DE2A430BA595` | — | — | 2026-08-01T08:09:43.9007556Z | 2026-08-01T08:09:29.6001808Z |
| `sqlite3.dll` | `858141A2826F53E8374CB07DE2638E0F1AC944F49B897DD558FEBA5597E86D1C` | — | — | 2026-08-01T08:09:43.9162354Z | 2026-08-01T08:07:55.5373735Z |
| `url_launcher_windows_plugin.dll` | `07F41F595B6E1B001B14B7A11320644E3B6EBB9E7F74130547B0A643BC779288` | — | — | 2026-08-01T08:09:43.9268158Z | 2026-08-01T08:09:34.3963212Z |
| `window_manager_plugin.dll` | `8E11F7AB204E27D9762EEF86F14DB593CE433A7F820D9773F3C3A265A2BEFE6A` | — | — | 2026-08-01T08:09:43.9338158Z | 2026-08-01T08:09:38.6159123Z |

`flutter_windows.dll` and `sqlite3.dll` are exactly identical across installed v1.1.0, cleanly rebuilt v1.1.0, and fresh v1.2.0. All MSVC-built plugin DLLs changed hash. `dartjni.dll` is stale installed residue: it is absent from both clean v1.1.0 and v1.2.0 outputs.

## Code Integrity evidence

The complete Movia-related enforced blocks observed in the log are:

| UTC | IDs | File | Status | Requested / validated | Flat SHA-256 | Rule/signer result |
|---|---|---|---|---|---|---|
| 2026-08-01T08:05:27Z and 08:05:41Z | 3033 + 3077 | first fresh `Movia-Desktop-Setup-1.2.0.exe` in repository and `C:\tmp` | `0xC0E90002` (`3236495362`) | 2 / 1 | `1531B3E3BCC0288B8B69AE7A06378E16188C26A6D61A04CB3D72D568F2D03B24` | No signer; no catalog; no rule ID emitted; implicit reputation/signing failure |
| 2026-08-01T08:07:09Z | 3033 + 3077 | first-build `desktop_multi_window_plugin.dll` | `0xC0E90002` | 2 / 1 | `DCB74D2E13F4A265FD91A682A84882EA55CB4BB7155FACEEBBBB265932390686` | No signer or metadata; loader stopped at this first rejected plugin |
| 2026-08-01T08:10:01Z | 3033 + 3077 | current `staging\windows-release\movia_desktop.exe` | `0xC0E90002` | 2 / 1 | `33340EFE2ECB17BD9931C059EF2926DD63DC00EFCF8AACE3682E564437F91849` | No signer; no catalog; no explicit rule ID |
| 2026-08-01T08:10:37Z | 3033 + 3077 | current `Movia-Desktop-Setup-1.2.0.exe` via Explorer | `0xC0E90002` | 2 / 1 | `D9AADEC342822DFFF0F544F14E8B915771E30DA63BA68D5BA3C34DBB445FBD80` | No signer; no catalog; no explicit rule ID |

The log proves direct enforcement by policy `{0283ac0f-fff1-49ae-ada1-8a933130cad6}`. Event 3033 is the concise signing-level failure; 3077 supplies hashes, metadata, policy name/hash/GUID, and signing scenario. No 3089 signer chain is produced because the files are unsigned.

Only `desktop_multi_window_plugin.dll` is individually observed blocked: loading stops at the first rejected dependency, so it would be inaccurate to label every remaining DLL as separately blocked. `flutter_windows.dll` and `sqlite3.dll` have already-trusted identical hashes; the remaining new-hash plugin DLLs are expected to require reputation or administrator authorization but were not independently proven blocked by the application loader.

## Toolchain and dependency reproduction

The controlled reproduction used detached tag `v1.1.0` at `78d55b0`, its unmodified lockfile, Flutter 3.44.8 stable revision `058e0af2c2`, engine `13ffd72b2f9a5ca4db2a74ea52d5353ec2e8f939`, Dart 3.12.2, x64 Release, and the original plugin list. The current and v1.1.0 `pubspec.lock` Git hashes are identical: `9dbd11be9e79c99fe79e86dc98181535d2bf28a1`.

The clean v1.1.0 rebuild completed, but did not reproduce the trusted installed hashes:

| File | Installed v1.1.0 | Clean rebuilt v1.1.0 | Result |
|---|---|---|---|
| `movia_desktop.exe` | `02FAFD51…C853` | `36DB625E…7484` | Different |
| `desktop_multi_window_plugin.dll` | `37CDEBCB…A66E` | `0E3D1367…EA51` | Different |
| `file_selector_windows_plugin.dll` | `9BC9B8FE…78DC` | `E80FF45E…F4EB` | Different |
| `flutter_windows.dll` | `890B2340…BB80` | `890B2340…BB80` | Identical |
| `screen_retriever_windows_plugin.dll` | `3A868F9D…2721` | `D8CB7E74…F743` | Different |
| `sqlite3.dll` | `858141A2…6D1C` | `858141A2…6D1C` | Identical |
| `url_launcher_windows_plugin.dll` | `E700AEF5…1F1F` | `B9779C80…8BBA` | Different |
| `window_manager_plugin.dll` | `2F9BB7B0…9205` | `F626F372…BB21` | Different |
| `dartjni.dll` | present | absent | Installed stale residue |

The native MSVC plugin outputs are not reproducible byte-for-byte under this process. Reusing exact dependencies does avoid unnecessary version drift, but does not legitimately transfer ISG reputation or guarantee the old hash. Copying old plugin DLLs into v1.2.0 is not recommended: it would create an unverified mixed build and would not authorize the changed main executable or installer.

## Resolution paths

### A. Exact old toolchain and DLLs

Insufficient. It reproduced only the prebuilt Flutter engine and SQLite hashes. The application executable and plugin DLLs changed. Cached trust is file-specific and is not a source-code property.

### B. Existing trusted production certificate

Valid if the owner or organization already has a code-signing certificate accepted by this policy. The installer, main EXE, and every non-Microsoft/plugin DLL must be signed and verified. No such certificate was found or used in this investigation.

### C. Catalog

Valid for administrator-managed deployment. Generate a catalog covering the finalized installer/package binaries, sign it with an organization certificate trusted by the active policy, deploy the catalog, and verify all hashes. Microsoft documents catalog generation/deployment at [Deploy catalog files](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/app-control-for-business/deployment/deploy-catalog-files-to-support-appcontrol).

### D. Managed Installer

Valid only if an administrator configures and trusts the deployment system as a Managed Installer and the active policy enables Managed Installer authorization. The current Movia installation has no documented Managed Installer origin claim.

### E. Supplemental allow policy

Valid if the controlling base policy allows supplemental policies. An administrator should generate file-publisher rules where signed metadata permits and SHA-256/Authenticode hash rules for unsigned Movia binaries, include all final EXEs and DLLs, test in audit mode on a representative device, sign/deploy the supplemental policy as required, and then verify with Code Integrity events. `citool -lp` returned access denied in the non-elevated investigation, so an administrator must confirm whether supplemental policies are permitted.

### F. Unrestricted personal Windows validation

Valid and lowest-risk for completing product QA without changing this machine's protection. It does not make v1.2.0 compatible with this protected machine; it only provides a clean environment for installer/UI validation.

## Exact administrator action

For this protected machine, the administrator must choose one approved trust path:

1. Deploy the finalized Movia package with an already-authorized Managed Installer, if policy option 13 is enabled; or
2. Create and deploy an approved supplemental App Control policy containing allow rules for the finalized v1.2.0 installer, EXE, and all DLLs, after confirming the base permits supplements; or
3. Create a catalog for all final Movia binaries, sign it with the organization's already-trusted code-signing identity, and deploy that catalog through normal management.

The administrator should collect `citool -lp` from an elevated session, export/decompile the applicable policy with approved tooling, confirm options 13, 14, and 17, stage the chosen authorization in audit/test scope, and then promote it through the organization's normal change control. No policy weakening is required.

## Source-code impact and recommendation

No Flutter/Dart source-code change can make an unknown unsigned binary satisfy Smart App Control reputation or an enterprise signing level. Build determinism and minimizing dependencies are worthwhile engineering improvements, but they are not authorization mechanisms.

Recommended lowest-risk path:

1. Complete visual and installer validation on an unrestricted personal Windows test environment.
2. Freeze the exact final artifacts and hashes.
3. For this protected machine, ask the administrator to deploy a narrowly scoped supplemental allow policy or approved catalog for those frozen artifacts. Prefer the organization's Managed Installer if one already exists and is enabled.
4. Do not rely on copying internal EAs or waiting for reputation to change; Microsoft states reputation can change over time and is not a deterministic release channel.
