---
title: 'Venv at home: My solution to "error: externally-managed-environment"'
tags: python
redirect_from: /p/79
---

Since Python 3.12 (which enforces [PEP 668](https://peps.python.org/pep-0668/)) shipped with Ubuntu 24.04, like many others, I found my usual habit of installing PyPI packages to my user site directory (`~/.local`) no longer working due to the `externally-managed-environment` restriction.

I consider it a perfectly valid and common use case to install some frequently-used packages (e.g. `regex`, `requests`, `mkdocs`) to my home directory so that they're conveniently available whenever and wherever I start a `python3` REPL shell.

Fortunately, it's not hard to find a straightforward workaround once you know [this](https://docs.python.org/3/library/sys_path_init.html):

> If `PYTHONHOME` is not set, and **a `pyvenv.cfg` file is found** [...] **in its parent directory**,
> `sys.prefix` and `sys.exec_prefix` get set to the directory containing `pyvenv.cfg`, [...].
> This is used by Virtual Environments.

So if we can trick Python into thinking `~/.local` is a virtual environment, the issue resolves itself.
It's not hard to figure out the required content for `~/.local/pyvenv.cfg`, much less writing it.

```ini
include-system-site-packages = true
```

Of course an empty `pyvenv.cfg` will do the trick, but including system packages allows you to skip some redundancy between your user site and system site directories.

We also need to ensure that Python is invoked from `~/.local/bin`:

```shell
ln -sfn /usr/bin/python3 ~/.local/bin/python3
```

However, `pip3` still complains about `externally-managed-environment`.
This is because the Python interpreter that runs `pip3` is still launched from the system path (`/usr/bin/python3`) due to the shebang line.
To fix this, just call `pip` with our desired path to Python:

```shell
# Assuming ~/.local/bin comes early in $PATH
python3 -m pip install -U pip
```

We can now inspect the new `pip3` command at the new location:

```shell
$ head -1 $(which pip3)
#!/home/ubuntu/.local/bin/python3
```

Now this `pip3` command will happily install any requested package into `~/.local/lib` without complaining about environments:

```shell
$ pip3 install --user --upgrade humanize
Looking in indexes: https://mirrors.ustc.edu.cn/pypi/simple
Requirement already satisfied: humanize in /usr/lib/python3/dist-packages (4.12.1)
Collecting humanize
  Using cached https://mirrors.ustc.edu.cn/pypi/packages/c5/7b/bca5613a0c3b542420cf92bd5e5fb8ebd5435ce1011a091f66bb7693285e/humanize-4.15.0-py3-none-any.whl (132 kB)
Installing collected packages: humanize
Successfully installed humanize-4.15.0
```

We don't need the `--user` flag anymore but I kept it as a habit of being explicit.

## Using `uv` {#uv}

Python `pip` has no idea when a package is installed and *why*, and in particular it does not know the difference between your package demands and what has been installed.
If your `requirements.txt` undergoes changes and you want to ensure you have exactly the necessary set of packages installed, your best bet is to delete your `venv` and create it anew.

So here comes [uv], a next-generation package *manager* for Python, whereas `pip` is at best a package *downloader*.
As uv is designed for managing virtual environments within projects, some minor hacks are needed to make it treat `~/.local` as our venv, instead of creating another `.venv` directory.
This is laid out in the [uv documentation](https://docs.astral.sh/uv/reference/environment/#uv_project_environment).

  [uv]: https://docs.astral.sh/uv/

```shell
export UV_PROJECT_ENVIRONMENT=~/.local
```

I also migrated my manual installations to a proper `pyproject.toml`:

```toml
[project]
name = "home"
version = "0.0.1"
requires-python = ">=3.12, <4.0"
dependencies = [
  "jieba",
  "matplotlib",
  "mkdocs (>=1.6.1, <2)",
  "mkdocs-material~=9.7.6",
  "numpy",
  "python-telegram-bot==13.15",
  "regex",
  "requests",
  "tabulate",
  "yt-dlp",
]
```

Now we can simply run `uv sync` to have our desired packages ready with no fluff, and `uv sync --upgrade` to upgrade them when needed:

```shell
$ uv sync --upgrade
Resolved 71 packages in 517ms
Prepared 1 package in 447ms
Uninstalled 2 packages in 57ms
Installed 1 package in 45ms
 - humanize==4.15.0  # oops
 - yt-dlp==2026.3.3
 + yt-dlp==2026.3.13
```

Because the environment variable `UV_PROJECT_ENVIRONMENT` is mandatory, I also created a Makefile to streamline command-line workflow:

```makefile
export UV_PROJECT_ENVIRONMENT = $(HOME)/.local

.PHONY: sync upgrade
sync:
  uv sync

upgrade:
  uv sync --upgrade
```

Now whenever I need another package inside my "home environment", I simply edit `pyproject.toml` here and run `make`.
`uv` will ensure a consistent and sane package state, and I'll never worry about `pip` again.
