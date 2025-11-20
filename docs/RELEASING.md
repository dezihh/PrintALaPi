# Creating Releases for PrintALaPi

This guide explains how to create releases for the PrintALaPi project.

## Overview

The PrintALaPi project uses an automated release process via GitHub Actions. When a version tag is pushed, the workflow automatically builds the Raspberry Pi OS image and creates a GitHub release with the built image attached.

## Release Process

### 1. Update Version Files

Before creating a release, update the following files:

**VERSION**
```
1.0.0
```

**CHANGELOG.md**
Add a new section at the top with the new version:
```markdown
## [1.1.0] - YYYY-MM-DD

### Added
- New feature 1
- New feature 2

### Changed
- Modified feature 1

### Fixed
- Bug fix 1
```

### 2. Commit Changes to Main Branch

```bash
git checkout main
git pull origin main
git add VERSION CHANGELOG.md
git commit -m "Prepare release v1.0.0"
git push origin main
```

### 3. Create and Push Tag

```bash
# Create annotated tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag to trigger release workflow
git push origin v1.0.0
```

### 4. Monitor Release Build

1. Go to the repository's Actions tab
2. Watch the "Build PrintALaPi Image" workflow
3. The workflow will:
   - Download Raspberry Pi OS Lite base image
   - Customize the image with PrintALaPi scripts
   - Compress the final image
   - Create a GitHub release
   - Upload the compressed image as a release asset

### 5. Review and Publish Release

Once the workflow completes:
1. Go to the repository's Releases page
2. Find the newly created release
3. Review the release notes (auto-populated from CHANGELOG.md)
4. Edit if needed to add additional context
5. Release will be published automatically (not a draft)

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version (1.x.x) - Incompatible API changes
- **MINOR** version (x.1.x) - New functionality in a backwards compatible manner
- **PATCH** version (x.x.1) - Backwards compatible bug fixes

## Release Notes Template

Use the `.github/RELEASE_TEMPLATE.md` as a guide for creating comprehensive release notes. The template includes:

- Overview of what's included
- Installation instructions
- Requirements
- Documentation links
- Features list
- Known issues
- Support information

## Pre-release Testing

Before creating an official release:

1. **Test the build process locally**:
   ```bash
   cd build
   sudo ./customize-image.sh
   ```

2. **Test the image on actual hardware**:
   - Flash to SD card
   - Boot Raspberry Pi
   - Verify all services start correctly
   - Test printer functionality
   - Verify web interface accessibility

3. **Check documentation**:
   - Ensure README is up to date
   - Verify installation instructions
   - Update any outdated information

## Troubleshooting

### Workflow Fails to Create Release

**Problem**: The workflow runs but doesn't create a release.

**Solutions**:
- Verify the tag starts with 'v' (e.g., v1.0.0, not 1.0.0)
- Check that repository permissions allow workflow to write
- Ensure `GITHUB_TOKEN` has proper permissions

### Image Build Fails

**Problem**: The image customization step fails.

**Solutions**:
- Check the build logs in GitHub Actions
- Verify all scripts in `scripts/` directory are executable
- Test the build process locally before tagging

### Release Asset Not Uploaded

**Problem**: Release is created but image file is missing.

**Solutions**:
- Verify the image compression step completed successfully
- Check that the file path in the workflow matches the actual output
- Review the "Upload artifact" step logs

## Example: Creating v1.0.0

```bash
# Update version and changelog
echo "1.0.0" > VERSION
# Edit CHANGELOG.md to add v1.0.0 section

# Commit changes
git add VERSION CHANGELOG.md
git commit -m "Prepare release v1.0.0"
git push origin main

# Create and push tag
git tag -a v1.0.0 -m "Release version 1.0.0 - First official release"
git push origin v1.0.0

# Watch the workflow at:
# https://github.com/dezihh/PrintALaPi/actions
```

## Release Checklist

Before creating a release:

- [ ] Update VERSION file
- [ ] Update CHANGELOG.md
- [ ] Test build process locally
- [ ] Update documentation if needed
- [ ] Commit all changes to main branch
- [ ] Create annotated git tag
- [ ] Push tag to trigger workflow
- [ ] Monitor workflow execution
- [ ] Verify release is created successfully
- [ ] Test the released image
- [ ] Announce the release

## Post-Release

After a successful release:

1. **Announce the release**:
   - Update project README if it references the latest version
   - Create a discussion post about the release
   - Share on relevant communities

2. **Monitor for issues**:
   - Watch for bug reports related to the new release
   - Be prepared to create a patch release if critical issues are found

3. **Plan next release**:
   - Create milestones for the next version
   - Label issues and PRs for the next release cycle

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
