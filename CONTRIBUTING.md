# Contributing to X-Terraform Agent

Thank you for your interest in contributing to X-Terraform Agent! This document provides guidelines for contributing to this project.

## 🤝 How to Contribute

### **Fork and Pull Request Workflow**

1. **Fork the repository** to your GitHub account
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/x-terraform.git
   cd x-terraform
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make your changes** and commit them:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```
5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Create a Pull Request** from your fork to the main repository

### **Branch Naming Convention**

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `test/` - Test improvements
- `refactor/` - Code refactoring
- `chore/` - Maintenance tasks

### **Commit Message Format**

Use conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance

## 🧪 Development Setup

### **Prerequisites**
- Python 3.9+
- Terraform
- Ollama (for AI features)

### **Local Development**
```bash
# Clone and setup
git clone https://github.com/YOUR_USERNAME/x-terraform.git
cd x-terraform

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run tests
python -m pytest tests/
```

## 📋 Pull Request Guidelines

### **Before Submitting a PR**

1. **Ensure all tests pass**:
   ```bash
   python -m pytest tests/
   ```

2. **Check code style**:
   ```bash
   black agent/
   flake8 agent/
   ```

3. **Update documentation** if needed

4. **Add tests** for new features

### **PR Description Template**

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Test improvement
- [ ] Other (please describe)

## Testing
- [ ] All tests pass
- [ ] Manual testing completed
- [ ] Offline mode tested (if applicable)

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

## 🚨 Security

- **Never commit sensitive information** (API keys, passwords, etc.)
- **Use environment variables** for configuration
- **Report security issues** privately to maintainers

## 📞 Getting Help

- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Discussions**: Use GitHub Discussions for questions and general discussion
- **Documentation**: Check the [README.md](README.md) and [docs/](docs/) folder

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to X-Terraform Agent! 🚀 