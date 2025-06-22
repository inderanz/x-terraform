"""
Setup script for Terraform Agent.
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read the README file
this_directory = Path(__file__).parent
long_description = (this_directory / "README.md").read_text()

# Read requirements
requirements = (this_directory / "requirements.txt").read_text().splitlines()

setup(
    name="terraform-agent",
    version="1.0.0",
    author="Terraform Agent Team",
    author_email="team@terraform-agent.dev",
    description="A production-grade AI agent for Terraform development",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/your-org/terraform-agent",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: System :: Systems Administration",
        "Topic :: Utilities",
    ],
    python_requires=">=3.9",
    install_requires=requirements,
    extras_require={
        "dev": [
            "pytest>=7.4.3",
            "pytest-asyncio>=0.21.1",
            "pytest-cov>=4.1.0",
            "black>=23.11.0",
            "isort>=5.12.0",
            "flake8>=6.1.0",
            "mypy>=1.7.1",
        ],
        "docs": [
            "mkdocs>=1.5.3",
            "mkdocs-material>=9.4.8",
        ],
    },
    entry_points={
        "console_scripts": [
            "terraform-agent=agent.main:main",
        ],
    },
    include_package_data=True,
    package_data={
        "agent": ["*.py", "**/*.py"],
        "config": ["*.env"],
    },
    keywords="terraform, ai, agent, infrastructure, devops, ollama",
    project_urls={
        "Bug Reports": "https://github.com/your-org/terraform-agent/issues",
        "Source": "https://github.com/your-org/terraform-agent",
        "Documentation": "https://terraform-agent.dev",
    },
) 