# Xcode Setup Guide

This guide will help you configure the EnergyAtlas project in Xcode after the rename.

## Current Status

✅ Bundle identifiers updated to `com.skyporch.EnergyAtlas`  
✅ All Swift files renamed and updated  
✅ Project structure organized  

## Steps to Complete in Xcode

### 1. Close and Reopen Xcode

If you have the project open, close Xcode completely and reopen:

```bash
# Close Xcode, then:
open EnergyAtlas.xcodeproj
```

### 2. Verify Project Settings

1. Select the **EnergyAtlas** project in the navigator
2. Select the **EnergyAtlas** target
3. Go to the **General** tab
4. Verify:
   - **Display Name**: Energy Atlas
   - **Bundle Identifier**: `com.skyporch.EnergyAtlas`
   - **Version**: 1.0.0
   - **Build**: 1

### 3. Update Bundle Identifier (Optional)

If you want to use your own organization identifier:

1. Change `com.skyporch.EnergyAtlas` to `com.yourorg.EnergyAtlas`
2. Update in both:
   - Main app target
   - Test target

### 4. Configure Signing

1. Go to **Signing & Capabilities** tab
2. Select your **Team**
3. Xcode will automatically manage signing

### 5. Check File References

In the Project Navigator, verify all files are found (not red):

- ✅ All files should be black (found)
- ❌ Red files = missing references

If you see red files:
1. Right-click the red file
2. Select "Show in Finder"
3. If file exists, delete reference and re-add
4. If file doesn't exist, remove reference

### 6. Build the Project

Press **Cmd + B** to build.

**Expected**: Build should succeed with no errors.

If you get errors:
- Check that all file paths are correct
- Verify RealityKitContent package is found
- Clean build folder: **Cmd + Shift + K**

### 7. Run the Project

1. Select target: **Vision Pro** or **visionOS Simulator**
2. Press **Cmd + R** to run
3. Verify the app launches and displays "Energy Atlas"

### 8. Test Key Features

- [ ] Intro screen appears
- [ ] "Enter Energy Atlas" button works
- [ ] Globe loads and displays
- [ ] Control panel appears
- [ ] Year slider works
- [ ] Country selection works
- [ ] Metric carousel rotates
- [ ] Chart panel toggles
- [ ] AI panel opens (if visionOS 2.6+)

## Common Issues & Solutions

### Issue: Red file references

**Solution**: The file reorganization may have broken some Xcode references.

1. Delete red references
2. Right-click on folder in navigator
3. "Add Files to EnergyAtlas..."
4. Select the files from their new locations
5. Uncheck "Copy items if needed"

### Issue: "No such module 'RealityKitContent'"

**Solution**: 
1. Close Xcode
2. Delete `~/Library/Developer/Xcode/DerivedData/EnergyAtlas-*`
3. Reopen project
4. Clean and rebuild

### Issue: Signing errors

**Solution**:
1. Select your development team
2. Or change bundle ID to something unique
3. Enable "Automatically manage signing"

### Issue: Build succeeds but app crashes

**Solution**:
1. Check that all resource files (CSV, m4a) are in the bundle
2. Verify in Build Phases → Copy Bundle Resources
3. Add missing resources if needed

## Updating Info.plist

The `Info.plist` already has:
- Display Name: "Energy Atlas"
- Immersion style: Mixed

No changes needed unless you want to customize further.

## Next Steps After Verification

Once the project builds and runs successfully:

1. ✅ Mark Step 5 complete in OPEN_SOURCE_CHECKLIST.md
2. Proceed to Step 6: Git initialization
3. Then Step 7: GitHub repository creation

## Need Help?

If you encounter issues:
1. Check the error messages carefully
2. Clean build folder (Cmd + Shift + K)
3. Restart Xcode
4. Check file paths in Build Phases

---

**Ready to proceed?** Once the build succeeds, we'll initialize the git repository!
