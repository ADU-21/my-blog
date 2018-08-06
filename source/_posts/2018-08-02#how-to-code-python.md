---
title: How to Code Python
date: 2018-08-02 18:00:32
category: "Coding"
tags:
- Python 
- Study
thumbnail: /images/how_to_code_python.jpg
featured: true
---

Python is my favorite language because it's simple and fast. It has been 3 years since first time I learn python, I've wrote [a lot of article](https://www.duyidong.com/categories/Python/) about python inital in my first year coiding python, feel free to read it if you understand chinese well. 

this article will focus on engineering practice of python and include an example about how to build a tool with python. 

<!-- more -->

## Before we start

I believe that when you really embrace a new language, you have to spend a lot of time on tools and language ecology. The ecological community built by the huge community using group wisdom is full of all kinds of knowledge points. These knowledge points may be the traps of the previous people (Common Gotchas), based on the local consensus after the practice of the classic project. Idioms may also be a summary of the conceptual patterns, even aesthetics and Zen or Dao. These knowledge points work in the tool and language ecosystem, meaning you need to use the right tools and ecologically friendly gameplay to benefit from it.

### Tools

There is no best tool in the world, just choice one you most familiar with.

* **Pycharm**

If you don't want to spend too much time on preperation, I suggest you use Pycharm. It's out of box and has perfect function.

If you like to like to play with tools or Linux, like me, an editor may be your best choice. Python interpreter is not complex to setup, while you doing this, you may can have better understanding of python environment.

* **Sublime**

In my first year coding pyhon, I used Sublime Text3, it's an old editor have very nice package management system, I have a [sample configuration](https://s3.amazonaws.com/duyidong-archive/software/SublimeSetting.zip) which is very old (for python 3.4 ) you can download and unarchive to your sublime user setting folder, then you can simply use do something like `F2-go to define`,` F5-Run` . For what I knoe after VS code become popular, most plugin are update so solow now.

* **Vim** 

I'm now using vim more and more, because you don't have to install anything you can use it in almostly any kind of system.

For Viw if you just want use it as an editor to write some scripts, I think some text style configure would be enough for most people:

```
set textwidth=79  " lines longer than 79 columns will be broken
set shiftwidth=4  " operation >> indents 4 columns; << unindents 4 columns
set tabstop=4     " a hard TAB displays as 4 columns
set expandtab     " insert spaces when hitting TABs
set softtabstop=4 " insert/delete 4 spaces when hitting a TAB/BACKSPACE
set shiftround    " round indent to multiple of 'shiftwidth'
set autoindent    " align the new line indent with the previous line
```

If you want a more smart editor with auto complete function, go to definition, refator function, I suggest you use a package for that: [Pymode](https://github.com/python-mode/python-mode), and another plugin which is very popular for add directory named [nerdtree](https://github.com/scrooloose/nerdtree), I use [vim-plug](https://github.com/junegunn/vim-plug) to manage then , just run single command and put plugin you want you install in ~/.vimrc, you'll get your python environment now.

Command to install vim-plug:

```shell
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

~/.vimrc

```
call plug#begin('~/.vim/bundle')
Plug 'python-mode/python-mode', { 'branch': 'develop' }
Plug 'scrooloose/nerdtree'
call plug#end()
```

### Interpreter

Because Python is very simple to install, let's skip... However, heroes stay, you know that Python is actually just a language standard, it has more than one implementation, the official implementation is CPython, and Jython and IronPython. However, CPython's use as the most widely used interpreter is certainly the first choice for development.

Repl-Oriented Programming is a more easy way to get fast feedback, I nromally use `ipython` for that.

### Pyenv

OSX default python version is python2.7, But I prefer use python3+ which are more Object-Oriented rather than script. If you like to use different version but don't want to mess your environment just like me I suggest use [pyenv](https://github.com/pyenv/pyenv) to management your python version.

![](/images/pyenv_commands.png)

## Now let's Coding

My aim is create a command line tool like `tree` via python, let's call it `pytree`.

### Virtual environments - venv

After 3.3 version of python, there is a module named [venv](https://docs.python.org/3/library/venv.html) for creating lightweight “virtual environments” with their own site directories, optionally isolated from system site directories. Each virtual environment has its own Python binary (which matches the version of the binary that was used to create this environment) and can have its own independent set of installed Python packages in its site directories. After 3.4, it also provide an independent pip via venv.

The way to use is:

```bash
python -m venv /path/to/new/virtual/environment # Create new virtual env
. <venv>/bin/activate                           # Active virtual env
deactivate                                      # Exit virtual env 
```

Now let's start with create project directory:

![](/images/pyenv_inital.png)

You can entry python interactive mode and import pytest for verify your environment is ready.

### Project structure

Refer to [Packaging Python Projects](https://packaging.python.org/tutorials/packaging-projects/)，create project directories and files like this:

```
.
├── LICENSE
├── README.md
├── docs                           # Directory for documentation
├── pytree                         # Source code here
│   ├── __init__.py
│   └── __version__.py
├── setup.py                       # The build script for setuptools
├── tests                          # Test code in this directory
│   ├── __pycache__
│   └── test_pytree.py
└── venv                           # Virtual environment
    ├── bin
    ├── include
    ├── lib
    ├── pip-selfcheck.json
    └── pyvenv.cfg
```

You can distrubute your package via setuptool if you want:

```
pip install setuptools wheel twine
python3 setup.py sdist bdist_wheel     # Generating distribution archives

twine upload --repository-url https://test.pypi.org/legacy/ dist/*   # upload all of the archives under dist
pip install --index-url https://test.pypi.org/simple/ example_pkg    # Installing your newly uploaded package
```

### Test - pytest

[Pytest](https://docs.pytest.org/en/latest/contents.html) is a powerful testing framework which have more function than unittest, it provide [dependence injection](https://docs.pytest.org/en/latest/fixture.html) and can generate report with [pytest-html](https://github.com/pytest-dev/pytest-html). compatible with [nose](http://nose.readthedocs.io/en/latest/index.html) and unittest.

For writting test with pytest, the class has to start with `Test`, and function has to start with `test_`, we can also use setup.py to run pytest: `python setup.py pytest` , setup tool will put `.pytree/tests` into `PATH`. We cab also add an alias to pytest in setup.cfg：

```
# setup.cfg
[aliases]
test=pytest
```

then we can use `python setup.py test`  to run all the tests.

### Coding - docopt

Use the TDD approach to implement the pytree core functionality(`core.py`) and then consider how to turn it into a real command line program. The first problem to be solved is how to display which incoming parameters are needed in a user-friendly way. We expect pytree-h to provide some help information. In order not to re-create the wheel, it is easier to select the ready-made Option parsing library. Python's built-in [argparse](https://docs.python.org/3/library/argparse.html) is enough, but [docopt](http://docopt.org/) is worth trying.

add dependence in setup.py:

```python
# setup.py
...
install_requires=[docopt==0.6.2]
```

then run `python setup.py develop` to install dependency.

then continues coding `cli.py`.

## Build

Use [pyinstaller](https://www.pyinstaller.org/) to build an excutable commandline file(cross platform):

```bash
pyinstaller -F entry.py --clean
```

## CICD

After push your code to github, we want to see the feedback for code quality and functional, so we always like to run all tests on a central server, github can integrate with [travis CI](https://travis-ci.org/) do so.

```yaml
# .travis.yml
language: python
python:
  - "3.4"
  - "3.5"
  - "3.6"
  - "3.6-dev"
install:
  - python setup.py develop
script:
  - pytest
```

Copy Images status to README.md

![](/images/travis_ci_setup.png) 

> Now Source code is here: <https://github.com/ADU-21/pytree>

Some resources to learn: 

* [The Hitchhiker’s Guide to Python](https://docs.python-guide.org/#the-hitchhiker-s-guide-to-python)
* <https://docs.python-guide.org/dev/env/>
* https://lambeta.com/2018/07/18/the-way-to-python/