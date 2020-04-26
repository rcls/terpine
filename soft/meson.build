# -*- python -*-
project('terpine', ['c', 'cpp'],
        default_options: [
            'werror=True', 'b_staticpic=false', 'optimization=3'])

add_project_arguments(
    '-D_GNU_SOURCE',
    '-Wno-unused-parameter', '-Wno-psabi', '-Wmissing-declarations',
    '-march=skylake', '-mtune=skylake', '-flto',
    language : 'cpp')

openssl = dependency('openssl')
sqlite3 = dependency('sqlite3')
threads = dependency('threads')
terpine = static_library(
    'terpine',
    'database.cpp', 'fifo.cpp', 'model.cpp', 'packet.cpp', 'server.cpp',
    dependencies: [openssl, sqlite3, threads])
trpne80 = static_library(
    'trpne80',
    'database.cpp', 'fifo.cpp', 'model.cpp', 'packet.cpp', 'server.cpp',
    dependencies: [openssl, sqlite3, threads],
    cpp_args: '-DMASK80')

executable('start'   , 'start.cpp'   , link_with: terpine)
executable('record'  , 'record.cpp'  , link_with: terpine)
executable('check'   , 'check.cpp'   , link_with: terpine)
executable('extract' , 'extract.cpp' , link_with: terpine)

executable('dump'    , 'dump.cpp'    , link_with: terpine)

executable('single'  , 'single.cpp'  , link_with: trpne80)
executable('check80' , 'check80.cpp' , link_with: trpne80)

executable('sha1test', 'sha1test.c')
executable('ethsum'  , 'ethsum.c')
