python3 << EOF
import subprocess, sys, re, os
from os import path, kill
import vim
import IPython
from jupyter_client import KernelManager
from queue import Empty


def external_in_bg(cmd):
  """ Run an external command, either minimized if on windows, or in the
  background if on a unix system. """

  if vim.eval("has('win32')") == '1' or vim.eval("has('win64')") == '1':
    vim.command('!start /min ' + cmd)
  elif vim.eval("has('unix')") == '1' or vim.eval("has('mac')") == '1':
    vim.command('!' + cmd + ' &')
    
def echo(arg,style="Question"):
  try:
    vim.command("echohl %s" % style)
    vim.command("echom \"%s\"" % arg.replace('\"','\\\"'))
    vim.command("echohl None")
  except vim.error:
    print("-- %s" % arg)

# from http://serverfault.com/questions/71285/in-centos-4-4-how-can-i-strip-escape-sequences-from-a-text-file
strip = re.compile('\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]')
def strip_color_escapes(s):
  return strip.sub('',s)


## Window management

def vib_setup():
  """Do first time setup of the console buffer.
  
  Buffer must be the active window!"""
  vim.command("setlocal nonumber")
  vim.command("setlocal bufhidden=hide buftype=nofile ft=python noswf")
  # turn of auto indent (there is some custom indenting that accounts
  # for the prompt).  See vim-tip 330
  vim.command("setl noai nocin nosi inde=") 
  vim.command("syn match Normal /^>>>/")

  # mappings to control sending stuff from vipy
  vim.command('nnoremap <buffer> <silent> <cr> <ESC>:py3 enter_at_prompt()<CR>')
  vim.command('inoremap <buffer> <silent> <cr> <ESC>:py3 enter_at_prompt()<CR>')

  # add an auto command, so that the cursor always moves to the end
  # upon entereing the vipy buffer
  vim.command("au WinEnter <buffer> :python3 insert_at_new()")

  vim.command("setlocal statusline=\ VIPY:\ %-{g:ipy_status}")
  
  # handle syntax coloring a little better
  vim.command('call VipySyntax()') # avoid problems with \v being escaped in the regexps

  # Disable ALE in vipy
  vim.command('let b:ale_enabled = 0')


def get_bufname():
  return vim.eval("bufname('%')")

def return_to_window(bufname):
  win_nr = vim.eval('bufwinnr("{}")'.format(bufname))
  result = vim.command("{} wincmd w".format(win_nr))

def open_console(focus = True):
  bufname = get_bufname()
  # Open buffer in new split
  vim.command("split vipy.py")
  # Go to bottom
  vim.command('execute "normal! \<c-w>J"')
  # Set height
  vim.command('execute "normal! z8\<cr>"')

  if not focus:
    return_to_window(bufname)

def goto_vib(insert_at_end = False, focus = True):
  """Show the vib buffer."""
  buffer = get_vim_ipython_buffer()
  if buffer:
    if is_vim_ipython_open():
      if focus:
        # Use drop to jump to open window
        #vim.command("drop {}".format(buffer.name))
        return_to_window("vipy.py")
    else:
      open_console(focus)
  else:
    echo("Vipy not started. Maybe start it here?")

def hide_vib():
  """Hide the console if visible."""
  # TODO: make this not switch active windows
  buffer = get_vim_ipython_buffer()
  if buffer:
    if is_vim_ipython_open():
      # Jump to open window and quit
      #vim.command("drop {}".format(buffer.name))
      return_to_window("vipy.py")
      vim.command("quit")
      # Return to last active window
      vim.command("wincmd p")

def toggle_vib():
  if is_vim_ipython_open():
    hide_vib()
  else:
    goto_vib()

def is_vim_ipython_open():
  """Returns true if console window is open."""
  for w in vim.windows:
    if w.buffer.name is not None and w.buffer.name.endswith("vipy.py"):
      return True
  return False

def in_vipy():
  """Returns true if console window is active."""
  cbn = vim.current.buffer.name
  if cbn:
    return cbn.endswith('vipy.py')
  else:
    return False

def insert_at_new():
  """ Insert at the bottom of the file, if it is the ipy buffer. """
  if in_vipy():
    # insert at end of last line
    vim.command('normal G')
    #vim.command('startinsert!') 

def get_vim_ipython_buffer():
  """Return the vipy buffer object."""
  for b in vim.buffers:
    try:
      if b.name.endswith("vipy.py"):
        return b
    except:
      continue
  return None

def interrupt_kernel():
  km.interrupt_kernel()



EOF
