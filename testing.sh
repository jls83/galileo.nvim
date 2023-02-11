#! /bin/sh

f() {
    echo $1 | rg $2 -r $3
}

f \
    '/Users/jls83/other_projects/foo/bar.py' \
    '/Users/jls83/other_projects/([a-z_]+)/([a-z]+)\.cc' \
    '/Users/jls83/other_projects/$1/$2.h'

g() {
    echo $1 | rg $2
}
