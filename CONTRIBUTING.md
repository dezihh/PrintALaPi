# Contributing to PrintALaPi

Thank you for considering contributing to PrintALaPi! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to make PrintALaPi better!

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Steps to reproduce the problem
- Expected behavior vs actual behavior
- Your Raspberry Pi model and OS version
- Relevant logs or error messages

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:
- Use a clear, descriptive title
- Explain the current behavior and why it's insufficient
- Describe the proposed enhancement in detail
- Explain why this enhancement would be useful

### Pull Requests

1. **Fork the repository**
   ```bash
   git clone https://github.com/dezihh/PrintALaPi.git
   cd PrintALaPi
   ```

2. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add comments where necessary
   - Test your changes thoroughly

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: brief description of changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Include testing steps

## Development Guidelines

### Code Style

**Shell Scripts:**
- Use 4 spaces for indentation
- Add error handling with `set -e`
- Use meaningful variable names in UPPER_CASE
- Add comments for complex operations

**Python:**
- Follow PEP 8 style guide
- Use 4 spaces for indentation
- Add docstrings for functions
- Use meaningful variable names in snake_case

### Testing

Before submitting:
1. Test syntax: `bash -n script.sh`
2. Test on actual Raspberry Pi hardware if possible
3. Verify all services start correctly
4. Check logs for errors

### Documentation

- Update README.md if adding features
- Update INSTALL.md if changing installation process
- Add inline comments for complex code
- Update configuration examples if needed

## Project Structure

```
PrintALaPi/
├── .github/workflows/   # GitHub Actions
├── build/              # Image building scripts
├── scripts/            # Installation and setup scripts
├── config/             # Configuration templates
├── webserver/          # Web interface code
└── docs/               # Additional documentation
```

## Areas for Contribution

We especially welcome contributions in these areas:

- **Printer Drivers**: Adding support for more printer models
- **Web Interface**: Improving the configuration UI
- **Monitoring**: Enhanced SNMP monitoring features
- **Security**: Security improvements and hardening
- **Documentation**: Tutorials, guides, and translations
- **Testing**: Test scripts and validation tools
- **Performance**: Optimization and efficiency improvements

## Questions?

Feel free to open an issue with the label "question" if you need help or clarification.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
