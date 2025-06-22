"""
Git repository integration for the Terraform Agent.
"""

import os
from pathlib import Path
from typing import Dict, List, Optional, Any
import git
import structlog
from ..core.exceptions import GitError

logger = structlog.get_logger(__name__)

# Global repository instance
_repository: Optional['GitRepository'] = None


class GitRepository:
    """Git repository wrapper for Terraform Agent."""
    
    def __init__(self, repo_path: Optional[str] = None):
        self.repo_path = Path(repo_path) if repo_path else None
        self.repo: Optional[git.Repo] = None
        self._initialize_repository()
    
    def _initialize_repository(self):
        """Initialize git repository."""
        try:
            if self.repo_path:
                if not self.repo_path.exists():
                    raise GitError(f"Repository path does not exist: {self.repo_path}")
                
                if not (self.repo_path / ".git").exists():
                    logger.warning(f"Path is not a git repository: {self.repo_path}")
                    return
                
                self.repo = git.Repo(self.repo_path)
                logger.info(f"Initialized git repository: {self.repo_path}")
            else:
                # Try to find git repository in current directory
                current_path = Path.cwd()
                try:
                    self.repo = git.Repo(current_path, search_parent_directories=True)
                    self.repo_path = Path(self.repo.working_dir)
                    logger.info(f"Found git repository: {self.repo_path}")
                except git.InvalidGitRepositoryError:
                    logger.warning("No git repository found in current directory")
                    
        except Exception as e:
            logger.error(f"Failed to initialize git repository: {e}")
            raise GitError(f"Git initialization failed: {e}")
    
    def get_repository_info(self) -> Dict[str, Any]:
        """Get repository information."""
        if not self.repo:
            return {"error": "No git repository available"}
        
        try:
            return {
                "path": str(self.repo_path),
                "branch": self.repo.active_branch.name,
                "commit": self.repo.head.commit.hexsha,
                "commit_message": self.repo.head.commit.message.strip(),
                "author": self.repo.head.commit.author.name,
                "remote_urls": [remote.url for remote in self.repo.remotes],
                "is_dirty": self.repo.is_dirty(),
                "untracked_files": self.repo.untracked_files,
                "modified_files": [item.a_path for item in self.repo.index.diff(None)],
                "staged_files": [item.a_path for item in self.repo.index.diff('HEAD')]
            }
        except Exception as e:
            logger.error(f"Failed to get repository info: {e}")
            return {"error": str(e)}
    
    def find_terraform_files(self) -> List[Dict[str, Any]]:
        """Find all Terraform files in the repository."""
        if not self.repo_path:
            return []
        
        terraform_files = []
        terraform_extensions = {'.tf', '.tfvars', '.hcl'}
        
        try:
            for file_path in self.repo_path.rglob('*'):
                if file_path.is_file() and file_path.suffix in terraform_extensions:
                    # Skip .git directory
                    if '.git' in file_path.parts:
                        continue
                    
                    terraform_files.append({
                        "path": str(file_path.relative_to(self.repo_path)),
                        "absolute_path": str(file_path),
                        "size": file_path.stat().st_size,
                        "extension": file_path.suffix,
                        "modified": file_path.stat().st_mtime
                    })
            
            logger.info(f"Found {len(terraform_files)} Terraform files")
            return terraform_files
            
        except Exception as e:
            logger.error(f"Failed to find Terraform files: {e}")
            return []
    
    def get_file_content(self, file_path: str) -> Optional[str]:
        """Get content of a specific file."""
        if not self.repo_path:
            return None
        
        try:
            full_path = self.repo_path / file_path
            if full_path.exists():
                return full_path.read_text(encoding='utf-8')
            else:
                logger.warning(f"File not found: {file_path}")
                return None
        except Exception as e:
            logger.error(f"Failed to read file {file_path}: {e}")
            return None
    
    def get_recent_commits(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent commits."""
        if not self.repo:
            return []
        
        try:
            commits = []
            for commit in self.repo.iter_commits('HEAD', max_count=limit):
                commits.append({
                    "hash": commit.hexsha,
                    "message": commit.message.strip(),
                    "author": commit.author.name,
                    "date": commit.committed_datetime.isoformat(),
                    "files": list(commit.stats.files.keys())
                })
            return commits
        except Exception as e:
            logger.error(f"Failed to get recent commits: {e}")
            return []
    
    def get_file_history(self, file_path: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get commit history for a specific file."""
        if not self.repo:
            return []
        
        try:
            commits = []
            for commit in self.repo.iter_commits('HEAD', paths=file_path, max_count=limit):
                commits.append({
                    "hash": commit.hexsha,
                    "message": commit.message.strip(),
                    "author": commit.author.name,
                    "date": commit.committed_datetime.isoformat()
                })
            return commits
        except Exception as e:
            logger.error(f"Failed to get file history for {file_path}: {e}")
            return []
    
    def get_diff(self, file_path: Optional[str] = None) -> str:
        """Get current diff."""
        if not self.repo:
            return ""
        
        try:
            if file_path:
                return self.repo.git.diff(file_path)
            else:
                return self.repo.git.diff()
        except Exception as e:
            logger.error(f"Failed to get diff: {e}")
            return ""
    
    def is_clean(self) -> bool:
        """Check if repository is clean (no uncommitted changes)."""
        if not self.repo:
            return True
        
        try:
            return not self.repo.is_dirty()
        except Exception as e:
            logger.error(f"Failed to check repository status: {e}")
            return False


def get_repository() -> GitRepository:
    """Get the global repository instance."""
    global _repository
    if _repository is None:
        _repository = GitRepository()
    return _repository


def set_repository_path(repo_path: str):
    """Set repository path and reinitialize."""
    global _repository
    _repository = GitRepository(repo_path)


def create_repository(repo_path: str) -> GitRepository:
    """Create a new repository instance."""
    return GitRepository(repo_path) 