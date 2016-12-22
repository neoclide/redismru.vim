from os.path import expanduser
from .base import Base

class Source(Base):

  def __init__(self, vim):
    Base.__init__(self, vim)
    self.name = 'redis_mru'
    self.kind = 'file'
    self.home = expanduser('~')
    self.cwd = vim.eval('getcwd()') + '/'
    self.sorters = []

  def gather_candidates(self, context):
    items = self.vim.eval('redismru#files()')
    if len(context['args']) > 0 and context['args'][0] == '.':
      items = list(filter(lambda x: x.startswith(self.cwd), items))
      items = list(map(lambda x: x.replace(self.cwd,''), items))
    return [{'word': x.replace(self.home, '~'), 'action__path': x} for x in items]
