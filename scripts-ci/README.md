# iOS 云编译说明
Godot 4.4.1 → iOS Xcode project → xcodebuild unsigned compile.
This workflow does not sign an IPA and does not claim TrollStore/installable output.
GitHub Actions uploads build evidence even on failure. The iOS export template may require additional preset values; check export.log first.
