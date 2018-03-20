#!/usr/bin/env perl

use strict;
use utf8;
use open 'IO' => ':utf8';
use open ':std';

use FindBin;
use List::Util qw(reduce);

$| = 1;

my $data_dir = $FindBin::Bin."/data";

my %word_dict = ();
my %declension_dict = ();

if (@ARGV) {
    my $additional_file = shift @ARGV;
    open IN, "<", $additional_file or die;
    while (<IN>) {
        chomp;
        $declension_dict{lc($_)} = ();
    }
    close IN;
}

open IN, "<", "$data_dir/de_words.txt" or die;
while (<IN>) {
    chomp;
    my @F = split/\t/;
    my @words = map { lc; } split/,/;
    @word_dict{@words} = ();
    @declension_dict{@words} = ();
    @declension_dict{map { $_."s"; } grep { !m{[s\x{df}]$} } @words} = ();
    @declension_dict{map { $_."n"; } grep { m{[elr]$} } @words} = ();
    @declension_dict{map { $_."e"; } grep { m{[^e]$} } @words} = ();
    @declension_dict{map { $_."en"; } grep { m{[^e]$} } @words} = ();
    $declension_dict{substr($words[0], 0, length($words[0]) - 1)} = () if $words[0] =~ m{(?<![ie])e$} and length($words[0]) > 4;
    $declension_dict{substr($words[0], 0, length($words[0]) - 1)."s"} = () if $words[0] =~ m{(?<![ie])e$} and length($words[0]) > 4;
    if ($words[0] =~ m{er$}) {
        $declension_dict{$words[0]."in"} = ();
        $declension_dict{$words[0]."innen"} = ();
    }
}
close IN;

my %blacklist_dict = ();
open IN, "<", "$data_dir/de_blacklist.txt" or die;
while (<IN>) {
    chomp;
    $blacklist_dict{$_} = ();
}
close IN;

my %prefix_dict = ();
open IN, "<", "$data_dir/de_prefix.txt" or die;
while (<IN>) {
    chomp;
    $prefix_dict{$_} = ();
}
close IN;

my @adjective_decl = qw(e er en em es);

open IN, "<", "$data_dir/de_verb_adj.txt" or die;
while (<IN>) {
    chomp;
    my @F = split/\t/;
    if ($F[1] eq "a") {
        my $t = $F[0];
        $declension_dict{$F[0]} = ();
        $declension_dict{$F[0]} = () if $F[0] =~ s{e$}{};
        for my $decl(@adjective_decl) {
            $declension_dict{$F[0].$decl} = ();
        }
    }
    elsif ($F[1] eq "v") {
        my $orig = $F[0];
        $declension_dict{$F[0]} = ();
        $F[0] =~ s{n$}{};
        $prefix_dict{$F[0]} = ();
        $prefix_dict{$F[0]} = () if $F[0] =~ s{(?<![ie])e$}{};
        $declension_dict{$F[0]."er"} = ();
        $declension_dict{$F[0]."ers"} = ();
        $declension_dict{$F[0]."erin"} = ();
        $declension_dict{$F[0]."erinnen"} = ();
        $declension_dict{$F[0]."ung"} = ();
        if ($orig =~ s{e([lr]n)$}{$1}) {
            $declension_dict{$orig."er"} = ();
            $declension_dict{$orig."ers"} = ();
            $declension_dict{$orig."erin"} = ();
            $declension_dict{$orig."erinnen"} = ();
            $declension_dict{$orig."ung"} = ();

            $declension_dict{$F[0]."nde"} = ();
            $declension_dict{$F[0]."nder"} = ();
            $declension_dict{$F[0]."nden"} = ();
            $declension_dict{$F[0]."ndes"} = ();
        }
        else {
            $declension_dict{$F[0]."ende"} = ();
            $declension_dict{$F[0]."ender"} = ();
            $declension_dict{$F[0]."enden"} = ();
            $declension_dict{$F[0]."endes"} = ();
        }
    }
}
close IN;

my %freq_dict = ();
my %freq_dict_last = ();
open IN, "<", "$data_dir/de_freq.txt" or die;
while (<IN>) {
    chomp;
    my @F = split/\t/;
    $freq_dict{$F[0]} = $F[1];
    $freq_dict_last{$F[0]} = $F[2];
}
close IN;

my %small_dict = ();
open IN, "<", "$data_dir/de_small.txt";
while (<IN>) {
    chomp;
    $small_dict{$_} = ();
}
close IN;

add_eszett_keys(\%prefix_dict);
add_eszett_keys(\%declension_dict);
add_eszett_keys(\%freq_dict);
add_reduced_keys(\%prefix_dict);
add_reduced_keys(\%declension_dict);
add_reduced_keys(\%freq_dict);

while (<STDIN>) {
    chomp;
    s{\b(\p{Lu}\p{Ll}+)\b}{decompose($1);}eg;
    print $_."\n";
}

sub decompose {
    my $orig = shift;
    my $str = lcfirst($orig);
    if (exists $declension_dict{$str} or exists $small_dict{$str}) {
        return $orig;
    }
    else {
        my $ref = enum_candidates($str);
        if (scalar(@{$ref}) == 0) {
            return $orig;
        }
        else {
            for my $str_array_ref(sort {scalar(@{$a})<=>scalar(@{$b}) or (reduce { $a * $freq_dict{$b} } (1, @{$b}[0..$#{$b}-1])) * $freq_dict_last{${$b}[-1]} <=> (reduce { $a * $freq_dict{$b} } (1, @{$a}[0..$#{$a}-1])) * $freq_dict_last{${$a}[-1]} } @{$ref}) {
                return join("-", map { ucfirst; } @{$str_array_ref});
            }
        }
    }
}

sub enum_paths {
    my ($result, $history, $cur) = @_;
    for my $node(@{$cur}) {
        if ($node->[0] eq "") {
            push @{$result}, [@{$history}];
            return;
        }
        else {
            my @new_history = @{$history};
            unshift @new_history, $node->[0];
            enum_paths($result, \@new_history, $node->[1]);
        }
    }
} 

sub enum_candidates {
    my $word = shift;
    my $nodes;
    $nodes->[0] = [];
    push @{$nodes->[0]}, ["", undef];
    for my $i(0..length($word)) {
        my $left_nodes_ref = $nodes->[$i];
        next if not ref($left_nodes_ref);
        for my $j(2..length($word) - $i) {
            my $substr = substr($word, $i, $j);
            next if exists $blacklist_dict{$substr};
            next unless exists $declension_dict{$substr} or ($i + $j != length($word) and exists $prefix_dict{$substr});
            push @{$nodes->[$i + $j]}, [$substr, $left_nodes_ref];
            if ($substr =~ m{(.)\1$}) {
                push @{$nodes->[$i + $j - 1]}, [$substr, $left_nodes_ref];
            }
        }
    }
    my $result = [];
    if (not ref($nodes->[length($word)]) or scalar(@{$nodes->[length($word)]}) == 0) {
        return $result;
    }
    my $ref = [];
    enum_paths($ref, [], $nodes->[length($word)]);
    return $ref;
}

sub add_eszett_keys {
    my $dict_ref = shift;
    for my $key(keys %{$dict_ref}) {
        next if index($key, "ss") == -1;
        add_eszett_key($dict_ref, $key, $dict_ref->{$key}, 0);
    }
}

sub add_eszett_key {
    my ($dict_ref, $key, $value, $index) = @_;
    my $next_index = index($key, "ss", $index);
    if ($next_index != -1) {
        add_eszett_key($dict_ref, $key, $value, $next_index + 2);
        my $eszett_key = $key;
        substr($eszett_key, $next_index, 2, "\x{df}");
        add_eszett_key($dict_ref, $eszett_key, $value, $next_index + 1);
    }
    else {
        $dict_ref->{$key} = $value;
    }
}

sub add_reduced_keys {
    my $dict_ref = shift;
    for my $key(keys %{$dict_ref}) {
        next unless $key =~ m{([a-z])\1\1};
        my $reduced_key = $key;
        $reduced_key =~ s{([a-z])\1\1}{$1$1};
        $dict_ref->{$reduced_key} = $dict_ref->{$key};
    }
}
