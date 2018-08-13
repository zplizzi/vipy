python3 << EOF
import subprocess, sys, re, os
from os import path, kill
import vim
import IPython
from jupyter_client import KernelManager
from queue import Empty

## Helper functions
def vprint(msg): 
    if type(msg) == str:
        print(msg)
    if type(msg) == list:
        for line in msg:
            print(line)

def vcommand(cmds):
    if type(cmds) == str:
        vim.command(cmds)
    if type(cmds) == list:
        for cmd in cmds:
            vim.command(cmd)

def get_doc(word):
    msg_id = client.shell_channel.object_info(word)
    doc = get_doc_msg(msg_id)
    if len(doc) == 0:
        return ''
    else:
        # get around unicode problems when interfacing with vim
        return [d.encode(vim_encoding) for d in doc]

def get_doc_msg(msg_id):
    n = 13 # longest field name (empirically)
    b=[]
    try:
        content = get_child_msg(msg_id)['content']
    except Empty:
        # timeout occurred
        return ["no reply from IPython kernel"]

    if not content['found']:
        return b

    for field in ['type_name', 'base_class', 'string_form', 'namespace',
            'file', 'length', 'definition', 'source', 'docstring']:
        c = content.get(field, None)
        if c:
            if field in ['definition']:
                c = strip_color_escapes(c).rstrip()
            s = field.replace('_',' ').title() + ':'
            s = s.ljust(n)
            if c.find('\n')==-1:
                b.append(s + c)
            else:
                b.append(s)
                b.extend(c.splitlines())
    return b

def print_help():
    word = vim.eval('expand("<cfile>")') or ''
    doc = get_doc(word)
    if len(doc) == 0 :
        vib.append(doc)

## HELPER FUNCTIONS

def external_in_bg(cmd):
    """ Run an external command, either minimized if on windows, or in the
    background if on a unix system. """

    if vim.eval("has('win32')") == '1' or vim.eval("has('win64')") == '1':
        vim.command('!start /min ' + cmd)
    elif vim.eval("has('unix')") == '1' or vim.eval("has('mac')") == '1':
        vim.command('!' + cmd + ' &')

def goto_vib(insert_at_end=True):
    global vib
    try:
        name = get_vim_ipython_buffer().name
        vim.command('drop ' + name)
        if insert_at_end:
            vim.command('normal G')
            vim.command('normal $')
            #vim.command('startinsert!')
    except:
        echo("It appears that the vipy.py buffer was deleted.  If the ipython kernel is still open, you can create a new vipy buffer without reseting the python server by pressing CTRL-F12.  If the ipython server is no longer available, reset the server by pressing SHIFT-F12 and then CTRL-F12 to start it up again along with a new vipy buffer.")
        vib = None

def toggle_vib():
    if in_vipy():
        if len(vim.windows) == 1:
            vim.command('bprevious')
        else:
            vim.command('exe "normal \<C-w>p"')
    else:
        goto_vib()

def above_prompt():
    """ See if the cursor is above the last >>> prompt. """
    row, col = vim.current.window.cursor
    i = len(vib) - 1
    last_prompt = 0
    while i >= 0:
        if vib[i].startswith(r'>>> '):
            last_prompt = i + 1 # convert from index to line-number
            break
    if row < last_prompt:
        return True
    else:
        return False

def is_vim_ipython_open():
    """
    Helper function to let us know if the vipy shell is currently
    visible
    """
    for w in vim.windows:
        if w.buffer.name is not None and w.buffer.name.endswith("vipy.py"):
            return True
    return False

def in_vipy():
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
    """ Return the vipy buffer. """
    for b in vim.buffers:
        try:
            if b.name.endswith("vipy.py"):
                return b
        except:
            continue
    return False

def get_vim_ipython_window():
    """ Return the vipy window. """
    for w in vim.windows:
        if w.buffer.name is not None and w.buffer.name.endswith("vipy.py"):
            return w
    raise Exception("couldn't find vipy window")

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

def get_child_msg(msg_id):
  while True:
    # get_msg will raise with Empty exception if no messages arrive in 5 second
    m= client.shell_channel.get_msg(timeout=5)
    if m['parent_header']['msg_id'] == msg_id:
      break
    else:
      #got a message, but not the one we were looking for
      if debugging:
        echo('skipping a message on shell_channel','WarningMsg')
  return m

EOF
