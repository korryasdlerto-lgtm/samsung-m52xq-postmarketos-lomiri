#!/usr/bin/python3

import os
import sys
from pathlib import Path

organization = "camera.ubports"
application = "camera.ubports"
old_application = "com.ubuntu.camera"

xdg_config_home = Path(os.environ.get("XDG_CONFIG_HOME",
                                      Path.home() / ".config"))
old_config_file = xdg_config_home / organization / f"{old_application}.conf"
new_config_file = xdg_config_home / organization / f"{application}.conf"
if old_config_file.is_file() and not new_config_file.exists():
    old_config_file.rename(new_config_file)

old_pictures_path = Path.home() / "Pictures" / old_application
pictures_path = Path.home() / "Pictures" / application
if old_pictures_path.is_dir() and not pictures_path.exists():
    old_pictures_path.rename(pictures_path)

old_videos_path = Path.home() / "Videos" / old_application
videos_path = Path.home() / "Videos" / application
if old_videos_path.is_dir() and not videos_path.exists():
    old_videos_path.rename(videos_path)

if len(sys.argv) > 1:
    os.execvp(sys.argv[1], sys.argv[1:])
