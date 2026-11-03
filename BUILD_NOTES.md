# AimeeBugFixes Build Notes

## Build Configuration

**Output Path**: `C:\Users\TJ\Desktop\StationeersServer\mods\Workshop_3674960841\`
**Assembly Name**: `AimeeBugFixes.dll`

## Building the Project

### Using the build script (recommended):
```bash
.\build.bat
```

### Using dotnet CLI:
```bash
dotnet build --configuration Release --no-restore
```

## Important: NuGet Restore Issue

This project has a known issue with NuGet restore that produces the error:
```
error : Value cannot be null. (Parameter 'path1')
```

**Workaround**: Always use the `--no-restore` flag when building. A manual `project.assets.json` file has been provided in the `obj/` directory to support this.

### If the build fails with asset file errors:

1. Ensure `obj/project.assets.json` exists
2. Always use `--no-restore` flag
3. Clean bin and obj folders before rebuilding:
   ```bash
   rmdir /s /q bin obj
   dotnet build --configuration Release --no-restore
   ```

## Requirements

- .NET SDK 8.0.100 (configured in global.json)
- Visual Studio 2022 or Visual Studio Code with C# extension
- BepInEx installation at: `C:\Program Files (x86)\Steam\steamapps\common\Stationeers\BepInEx\`

## Output

After building successfully, the compiled DLL will be located at:
```
C:\Users\TJ\Desktop\StationeersServer\mods\Workshop_3674960841\AimeeBugFixes.dll
```
