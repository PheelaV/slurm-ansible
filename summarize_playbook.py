# /// script
# requires-python = ">=3.13"
# dependencies = []
# ///
"""Print contents of all files in the current directory."""

import sys
from pathlib import Path
from typing import Iterator, Optional


def get_all_files(directory: Optional[Path] = None) -> Iterator[Path]:
  """Return an iterator of all files in the given directory."""
  base_dir = directory or Path.cwd()
  return (
    path for path in base_dir.rglob("*") 
    if path.is_file() and not path.name.startswith(".")
  )


def print_file_contents(file_path: Path) -> None:
  """Print the contents of a file with a header."""
  try:
    print(f"\n{'=' * 40}")
    print(f"File: {file_path}")
    print(f"{'=' * 40}")
    
    with open(file_path, "r", encoding="utf-8") as f:
      print(f.read())
  except UnicodeDecodeError:
    print("Binary file - contents not displayed")
  except Exception as e:
    print(f"Error reading file: {e}")


def main() -> int:
  """Entry point for the script."""
  directory = Path(sys.argv[1]) if len(sys.argv) > 1 else None
  
  files = get_all_files(directory)
  file_count = 0
  
  for file_path in files:
    print_file_contents(file_path)
    file_count += 1
  
  print(f"\nTotal files processed: {file_count}")
  return 0


if __name__ == "__main__":
  sys.exit(main())