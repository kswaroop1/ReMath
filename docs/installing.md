## Installing ReMath

ReMath `0.x` packages are prerelease builds. Verify the filename and, where
appropriate, its SHA-256 value against `SHA256SUMS.txt` on the release page.

### Android

1. Download the `remath-<version>-android.apk` asset on the Android device.
2. Open it and allow installation from the browser or file-manager application
   when Android asks.
3. Install ReMath, then disable that temporary “install unknown apps” permission
   again if it is no longer needed.

The current CI-generated Android signing identity is **not upgrade-stable**.
Do not assume that a later prerelease APK can be installed over an earlier one.
Uninstalling an APK can remove its local ReMath progress, and export/restore is
not implemented yet. **EN-013 remains incomplete** until an owner-controlled
release keystore is stored securely and used consistently by the release job.

### Windows

The Windows asset is a portable application, not an installer. Keep the complete
extracted directory together; `remath.exe` needs its adjacent DLL and `data`
files.

The current package does not have trusted Windows code signing, so Windows may
retain a downloaded-file security marker. The preferred sequence is:

1. Download `remath-<version>-windows.zip`.
2. Right-click the downloaded ZIP, select **Properties**, select **Unblock**, and
   apply the change—unblock the ZIP before extracting it.
3. Extract the complete ZIP to an ordinary directory.
4. Double-click `remath.exe`.

If the ZIP was already extracted and double-clicking appears to do nothing, open
PowerShell and run:

```powershell
Get-ChildItem "C:\path\to\the\extracted\remath-directory" -Recurse |
    Unblock-File
```

Then double-click `remath.exe` again. This exact recovery was verified against
ReMath 0.1.11 on Windows. **EN-015 remains incomplete** until ReMath has a signed
installer/MSIX and a trusted publisher certificate.

### Apple and web artifacts

The iOS ZIP is a simulator build, not an installable iPhone package. The macOS
application is not currently signed or notarised. The web ZIP is intended for a
web host and does not run by double-clicking `index.html` with full offline
storage guarantees.
