A fork of johndgiese/vipy which uses Python 3, updates various out-of-date code, changes various keyboard shortcuts, and strips out a lot of functionality that I don't use.


If using pyenv, you'll need to install a kernelspec so that the system python can find the pyenv python.

`ipython kernel install --name "pyenv" --user`


Debugging:

If the above doesn't work, first do `which ipython` and make sure it points to the pyenv shim. If not uninstall the system jupyter/ipython packages first (`pip list`).
