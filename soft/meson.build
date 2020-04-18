# -*- python -*-
project('terpine', ['c', 'cpp'],
        default_options : ['werror=True', 'b_staticpic=false'])

add_project_arguments('-D_GNU_SOURCE', '-Wno-format-zero-length',
                      language : 'cpp')

openssl = dependency('openssl')
sqlite3 = dependency('sqlite3')
terpine = static_library(
    'terpine', 'database.cpp', 'check.cpp', 'fifo.cpp', 'packet.cpp',
    dependencies: [openssl, sqlite3])
trpne80 = static_library(
    'trpne80', 'database.cpp', 'check.cpp', 'fifo.cpp', 'packet.cpp',
    dependencies: openssl, cpp_args: '-DMASK80')

executable('start'     , 'start.cpp'     , link_with: terpine)
executable('record'    , 'record.cpp'    , link_with: terpine)

executable('dump'      , 'dump.cpp'      , link_with: terpine)
executable('ping_board', 'ping_board.cpp', link_with: terpine)
executable('run_check' , 'run_check.cpp' , link_with: terpine)
executable('single'    , 'single.cpp'    , link_with: trpne80)
executable('check80'   , 'check80.cpp'   , link_with: trpne80)

executable('sha1test', 'sha1test.c')
executable('ethsum'  , 'ethsum.c')

executable('db_check', 'db_check.cpp', link_with: terpine)
