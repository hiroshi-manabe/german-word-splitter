German Word Splitter 
====================

What's this?
------------

**German Word Splitter** is a Perl script that splits German compound words into their components. It can also recompose compound words, with or without hyphens according to the component words.

Usage
-----
./split_german.pl [--dict additional dictionary file] [--reverse] < input > output

Example
-------

$ echo "Image-Installationsdienstprogramm" | ./split_german.pl
Image-Installations-Dienst-Programm

$ echo "Image-Installations-Dienst-Programm" | ./split_german.pl --reverse
Image-Installationsdienstprogramm
