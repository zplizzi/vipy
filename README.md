A fork of johndgiese/vipy which uses Python 3, updates various out-of-date code, changes various keyboard shortcuts, and strips out a lot of functionality that I don't use.

Install:

So Vim will point to different versions of python depending on how it was installed. On Vim installed with brew on Mac, for example, it'll point to some brew version of Python. Since all the Vipy interface code (not your actual code which you're running through vipy) runs on this version of python, we need to get a couple of packages installed on it. The easiest way to do this is to open vim and type:

`py3 import os; print(os.__file__)`.

For me that prints `/usr/local/opt/python/Frameworks/Python.framework/Versions/3.7/lib/python3.7/os.py`, and the desired pip path is `/usr/local/opt/python/bin/pip3`. So not quite perfect but will help you hone in on the needed path.

Then you need to install `jupyter_client` and `ipython` using this pip.

Great, that's all that needs done to that python environment. 

Then you need to make an environment where your code will actually get executed. Install pyenv any which way and set up a 3.6.4 env. 

If using pyenv, you'll need to install a kernelspec so that the system python can find the pyenv python.

`ipython kernel install --name "pyenv" --user`

Not sure which python this needs to happen on tbh.

Now in theory things might work.. probably this doc needs more deets though.


Debugging:

If the above doesn't work, first do `which ipython` and make sure it points to the pyenv shim. If not uninstall the system jupyter/ipython packages first (`pip list`).


