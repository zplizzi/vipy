" This file is sourced when the user tries starting vim using the shortcuts
" defined in plugin/vipy.vim; the files are split like this to reduce startup
" time for sessions where vipy isn't used.

execute "source utils.vim"

let g:ipy_status="idle"

" let the user specify the IPython profile they want to use
if !exists('g:vipy_profile')
  let g:vipy_profile='default'
endif

if !exists('g:vipy_position')
  let g:vipy_position='rightbelow'
endif

if !exists('g:vipy_height')
  let g:vipy_height=10
endif

function! VipySyntax()
  syn region VipyIn start=/\v(^\>{3})\zs/ end=/\v\ze^.{0,2}$|\ze^\>{3}|\ze^[^.>]..|\ze^.[^.>].|\ze^..[^.>]/ contains=ALL transparent keepend
  syn region VipyOut start=/\v\zs^.{0,2}$|\zs^[^.>]..|\zs^.[^.>].|\zs^..[^.>]/ end=/\v\ze^\>{3}/ 
  hi link VipyOut Normal
endfunction

noremap <silent> <Leader>q :py3 vipy_shutdown()<CR><ESC>
inoremap <silent> <Leader>q :py3 vipy_shutdown()<CR><ESC>
vnoremap <silent> <Leader>q :py3 vipy_shutdown()<CR><ESC>

noremap  <silent> <leader>v :py3 toggle_vib()<CR>

python3 << EOF
import subprocess, sys, re, os
from os import path, kill

import vim
import IPython
from jupyter_client import KernelManager
from queue import Empty

class Vipy(object):
  def __init__(self):
    self.debugging = False
    self.monitor_subchannel = True   # update vipy 'shell' on every send?
    self.run_flags= "-i"       # flags to for IPython's run magic when using <F5>
    self.current_line = ''

debugging = False
monitor_subchannel = True   # update vipy 'shell' on every send?
run_flags= "-i"       # flags to for IPython's run magic when using <F5>
current_line = ''

try:
  status
except:
  status = 'idle'
try:
  length_of_last_input_request
except: 
  length_of_last_input_request = 0
try:
  vib
except:
  vib = False
try:
  km
except NameError:
  km = None

# get around unicode problems when interfacing with vim
vim_encoding = vim.eval('&encoding') or 'utf-8'


## STARTUP and SHUTDOWN
ipython_process = None
def vipy_startup():
  global km, fullpath, profile_dir, client, vib, status
  if not km:
    vim.command("augroup vimipython")
    vim.command("au CursorHold * :python3 update_subchannel_msgs()")
    vim.command("au FocusGained *.py :python3 update_subchannel_msgs()")

    # run shutdown sequense
    vim.command("au VimLeavePre :python3 vipy_shutdown()")
    vim.command("augroup END")

    count = 0
    profile = vim.eval('g:vipy_profile')
    profile_dir = vim.eval('system("ipython locate profile ' + profile + '")').strip()
    if not path.exists(profile_dir):
      echo("It doesn't appear that the IPython profile, %s, specified using the g:vipy_profile variable exists.  Creating the profile ..." % profile)
      external_in_bg('ipython profile create ' + profile)
      profile_dir = vim.eval('system("ipython locate profile ' + profile + '")').strip()

    fullpath = None
    ipy_args = []

    km = KernelManager()
    km.kernel_name = "pyenv"
    km.start_kernel()
    client = km.client()
    status = "idle"

    vib = get_vim_ipython_buffer()
    if not vib:
      bufname = get_bufname()
      open_console()
      # Return to last active window
      #vim.command("wincmd p")
      vib_setup()
      vib = get_vim_ipython_buffer()
      new_prompt(append=False)
      return_to_window(bufname)
    else:
      goto_vib()

    # Update the vipy shell when the cursor is not moving
    # the cursor hold is updated 3 times a second (maximum), but it doesn't
    # update if you stop moving
    vim.command("set updatetime=333") 
    #echo("Vipy start successful!")
  else:
    echo('Vipy has already been started!  Press SHIFT-F12 to close the current seeion.')

def vipy_shutdown():
  global km, vib
  
  status = 'idle'
  if km != None:
    try:
      km.shutdown_kernel()
    except:
      echo('The kernel must have already shut down.')
  else:
    echo('The kernel must have already shut down.')

  km = None
  
  # wipe the buffer
  try:
    if vib:
      if len(vim.windows) == 1:
        vim.command('bprevious')
      vim.command('bw ' + vib.name)
      vib = None
  except:
    echo('The vipy buffer must have already been closed.')
  try:
    vim.command("au! vimipython")
  except:
    pass



def if_vipy_started(func):
  def wrapper(*args, **kwargs):
    if km:
      func(*args, **kwargs)
    else:
      echo("You must start VIPY first, using <CTRL-F5>")
  return wrapper
      

## COMMAND LINE 
def enter_at_prompt():
  """ Remove prompts and whitespace before sending to ipython. """
  stop_str = r'>>>'
  cmds = []
  linen = len(vib)
  while linen > 0:
    # remove the last three characters
    cmd = vib[linen - 1]
    # only add the line if it isn't empty
    if len(cmd) > 4:
      cmds.append(cmd[4:]) 

    if cmd.startswith(stop_str):
      break
    else:
      linen -= 1
  if len(cmds) == 0:
    return
  cmds.reverse()

  cmds = '\n'.join(cmds)
  if cmds == 'cls' or cmds == 'clear':
    vim.command('normal zt')
    new_prompt(append=False)
  else:
    send(cmds)
    # make vim poll for a while
    ping_count = 0
    while ping_count < 30 and not update_subchannel_msgs():
      vim.command("sleep 20m")
      ping_count += 1

def new_prompt(goto=True, append=True):
  if append:
    vib.append('>>> ')
  else:
    vib[-1] = '>>> '
  if goto:
    vim.command('normal G')
    vim.command('normal $')
    #vim.command('startinsert!')

def format_for_prompt(cmds, firstline='>>> ', limit=False):
  # format and input text
  max_lines = 10
  lines_to_show_when_over = 4
  if not cmds == '':
    formatted = re.sub(r'\n',r'\n... ',cmds).splitlines()
    lines = len(formatted)
    if limit and lines > max_lines:
      formatted = formatted[:lines_to_show_when_over] + ['... (%d more lines)' % (lines - lines_to_show_when_over)]
    formatted[0] = firstline + formatted[0]
    return formatted
  else:
    return [firstline]

## IPYTHON-VIM COMMUNICATION
blankprompt = re.compile(r'^\>\>\> $')
def send(cmds, *args, **kargs):
  """ Send commands to ipython kernel. 

  Format the input, then print the statements to the vipy buffer.
  """
  formatted = None
  if status == 'busy':
    echo('Can not send commands while the python kernel is busy.')
    return
    """
  if not in_vipy():
    # Display executed code in the console window
    formatted = format_for_prompt(cmds, limit=True)

    # remove any prompts or blank lines
    while len(vib) > 1 and blankprompt.match(vib[-1]):
      del vib[-1]
      
    if blankprompt.match(vib[-1]):
      vib[-1] = formatted[0]
      if len(formatted) > 1:
        vib.append(formatted[1:])
    else:
      vib.append(formatted) 
      """
  val = client.execute(cmds, *args, **kargs)
  return val


def update_subchannel_msgs(debug=False):
  """ This function grabs messages from ipython and acts accordinly; note
  that communications are asynchronous, and furthermore there is no good way to
  repeatedly trigger a function in vim.  There is an autofunction that will
  trigger whenever the cursor moves, which is the next best thing.
  """
  global status, length_of_last_input_request
  newprompt = False
  gotoend = False # this is a hack for moving to the end of the prompt when new input is requested that should get cleaned up

  msgs = client.iopub_channel.get_msgs()
  #msgs += client.stdin_channel.get_msgs() # also handle messages from stdin
  for m in msgs:
    try:
      msg_type = m['header']['msg_type']
    except KeyError:
      continue
      
    s = None
    if msg_type == 'status':
      if m['content']['execution_state'] == 'idle':
        status = 'idle'
        newprompt = True
      else:
        newprompt = False
      if m['content']['execution_state'] == 'busy':
        print("status is busy")
        status = 'busy'
      vim.command('let g:ipy_status="' + status + '"')
    elif msg_type == 'stream':
      s = strip_color_escapes(m['content']['text'])
    elif msg_type == "execute_result":
      s = strip_color_escapes(m['content']['data']['text/plain'])
    elif msg_type == 'error':
      c = m['content']
      s = "\n".join(map(strip_color_escapes, c['traceback']))
    elif msg_type == 'crash':
      s = "The IPython Kernel Crashed!"
      s += "\nUnfortuneatly this means that all variables in the interactive namespace were lost."
      s += "\nHere is the crash info from IPython:\n"
      s += repr(m['content']['info'])
      s += "Type CTRL-F12 to restart the Kernel"
    
    if s: # then update the vipy buffer with the formatted text
      vib.append(s.splitlines())
    
  # move to the vipy (so that the autocommand can scroll down)
  if in_vipy():
    if newprompt:
      new_prompt()
    if gotoend:
      goto_vib()

  else:
    if newprompt:
      new_prompt(goto=False)
    if is_vim_ipython_open():
      goto_vib(insert_at_end=False)

      # scroll to the bottom of the screen if there is new input
      if msgs:
        vim.command('exe "normal G\<C-w>p"')
      else:
        vim.command('exe "normal \<C-w>p"')
  return len(msgs)

      
def with_subchannel(f, *args, **kwargs):
  "conditionally monitor subchannel"
  def f_with_update(*args, **kwargs):
    try:
      f(*args, **kwargs)
      if monitor_subchannel:
        update_subchannel_msgs()
    except AttributeError: #if km is None
      echo("not connected to IPython", 'Error')
  return f_with_update

@if_vipy_started
@with_subchannel
def run_this_file():
  #vim.command("normal! ggVG")
  fname = repr(vim.current.buffer.name) # use repr to avoid escapes
  fname = fname.rstrip('ru') # remove r or u if it is raw or unicode
  fname = fname[1:-1] # remove the quotations
  fname = fname.replace('\\\\','\\')
  msg_id = send("run %s %s" % (run_flags, fname))
  goto_vib()
  

@if_vipy_started
@with_subchannel
def run_this_line():
  msg_id = send(vim.current.line.strip())
  goto_vib()

ws = re.compile(r'\s*')
@if_vipy_started
@with_subchannel
def run_these_lines():
  # Copy the last visual selection into the z register
  vim.command('normal! gv"zy')
  lines = vim.eval("getreg('z')").splitlines()
  ws_length = len(ws.match(lines[0]).group())
  lines = [line[ws_length:] for line in lines]
  msg_id = send("\n".join(lines))
  goto_vib()

# TODO: add support for nested cells
# TODO: fix glitch where the cursor moves incorrectly as a result of cell mode
# TODO: suppress the text output when in cell mode
cell_line = re.compile(r'^\s*##[^#]?')
@if_vipy_started
@with_subchannel
def run_cell(progress=False):
  """ run the code between the previous ## and next ## """

  row, col = vim.current.window.cursor
  cb = vim.current.buffer
  nrows = len(cb)

  # find previous ## or start of file
  crow = row - 1
  cell_start = 0
  while crow > 0:
    if cell_line.search(cb[crow]):
      cell_start = crow
      break
    else:
      crow = crow - 1

  # find next ## or end of file
  crow = row
  cell_end = nrows
  while crow < nrows:
    if cell_line.search(cb[crow]):
      cell_end = crow
      break
    else:
      crow = crow + 1
  lines = cb[cell_start:cell_end]
  ws_length = len(ws.match(lines[0]).group())
  lines = [line[ws_length:] for line in lines]
  msg_id = send("\n".join(lines))

  if progress: # move cursor to next cell
    if cell_end >= nrows - 1:
      cell_end = nrows - 1
    vim.current.window.cursor = (cell_end + 1, 0)



EOF
