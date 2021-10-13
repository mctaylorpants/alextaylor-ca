---
title: find with -print0
kind: article
created_at: 2021-10-13
---

I like using `find` with `xargs` and `perl` to do find-and-replace. Like this:

~~~
$> find . -type f | xargs perl -p -i -e "s/old_string/new_string"
~~~

This works great, until you have filenames with spaces in them. Because `xargs` usually splits on newlines and/or spaces, a filename with a space will appear to `xargs` as two files:

~~~
$> ls -l find_test
total 16
-rw-r--r--  1 alextaylor  staff  11 13 Oct 15:17 I have spaces
-rw-r--r--  1 alextaylor  staff  11 13 Oct 15:18 i_have_underscores

$> find find_test/ -type f | xargs perl -p -i -e "s/old_string/new_string/"
Can't open find_test//I: No such file or directory, <> line 1.
Can't open have: No such file or directory, <> line 1.
Can't open spaces: No such file or directory, <> line 1.
~~~

What to do?

## `-print0` to the rescue

Using `find`'s `-print0` option will separate filenames with a null character, and `xargs` has a complementary `-0` character that will interpret these:

~~~
$> find find_test/ -type f -print0 | xargs -0 perl -p -i -e "s/old_string/new_string/"

# nothing to show... it worked!
~~~

