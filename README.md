German Word Splitter 
====================

What's this?
------------

**German Word Splitter** is a Perl script that can split German compound words into smaller parts.

Usage
-----
./split_german.pl [additional dictionary file] < input > output

Example
-------

$ echo "Wählen Sie im Listenfeld Inhaltsvorlage eine Ordnerinhaltskomponente aus." | ./split_german.pl
Wählen Sie im Listen-Feld Inhalts-Vorlage eine Ordner-Inhalts-Komponente aus.
