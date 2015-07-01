#!/usr/bin/env perl

# script to search for a give term or terms on a list of torrent
#   sites and report the number of results found.
# does not validate the searches (ie may include spurious results in
#   the count). Be sure you understand what you're searching for.
# websites are stored in sites.csv



use warnings;
use warnings qw (FATAL utf8);   #fatalise encoding glitches
use strict;
use utf8;       # so literals and identifiers can be in UTF-8
use v5.12;      # or later to get unicode_strings feature

use File::Slurp;
use Data::Dumper;
use LWP::UserAgent;

# number of timeouts on a website required before skipping
#   to the next site
my $timeout_limit = 2;
my %timeouts;

# read in the search terms
my @search_terms;
my $searches_file = 'searches';
open (SEARCHES, "<", $searches_file) or die "$1\n";
#chomp(@search_terms = (<SEARCHES>));
while (<SEARCHES>) {
    chomp;
    next if $_ =~ /#/;
    push (@search_terms, $_);
}
close(SEARCHES);

foreach (@search_terms) {
    # clean up search terms
    s/^\s*//;
    s/\s*$//;
    # add "s so searches are exact
}


my $file = 'sites.csv';

# slurp up the websites and search urls.
my %sites_results;
my %sites;

open (FILE, "<", $file) or die "$1\n";

while (<FILE>) {
    
    chomp;
    next if $_ =~ /.*#.*/;

    my ($key, $search, $results_regex, $no_results_regex) = split /,/;
    $key =~ s/^\s+//;
    $search =~ s/^\s+//;
    $results_regex =~ s/^\s+//;

    $sites{$key}{'url'} = $search;
    $sites{$key}{'results_regex'} = $results_regex;
    if (length $no_results_regex) {
        $sites{$key}{'no_results_regex'} = $no_results_regex;
    } else {
        $sites{$key}{'no_results_regex'} = 'CHEESY HACK UNDEFINED STRING';
    }
}


#print Dumper(\%sites);

# for each website, search for each artist
# search_term = Artist,New Album
# url = www.freemusic/com/?search=*/page1.html
# search_string = Artist%20New%20Album
# search_url = www.freemusic.com/?search=Artist%20New%20Album/page1.html

foreach my $site (keys (%sites)) {

    print "***$site***\n";

    my $url = $sites{$site}{'url'};
    # keep track of timeouts for each site so we dont sit through 
    #   too many if the site is down
    $timeouts{$site} = 0;


    foreach my $search_term (@search_terms) {

        print "$search_term\t";

        next if $search_term =~ /#/;
        if ($timeouts{$site} > $timeout_limit) {
            $sites_results{$site}{$search_term} = '0*';
            next;
        }

        # some sites can't handle quotations!
        my $search_string = $search_term;
        $search_string =~ s/^/\"/ if $site !~ 'torrentdownloads.me';
        $search_string =~ s/$/\"/ if $site !~ 'torrentdownloads.me';
        $search_string =~ s/,/\"%20\"/;
        $search_string =~ s/\s/%20/g;

        my $search_url = $url;
        $search_url =~ s/\*/$search_string/;
        

        my $ua = LWP::UserAgent->new();
        $ua->agent("Mozilla/6.0");
        $ua->timeout(10);
        my $referer = $url;
        my $response = $ua->get("$search_url", Referer => $referer, ACCEPT_LANGUAGE => 'en');
        #print "url: $search_url\n";

        my $useable_response = $response->decoded_content(charset => 'utf-8');
        $useable_response =~ s/[^[:ascii:]]+//g;


#       die "Can't get ".$search_url, ".$response->status_line."\n"
#           unless $response->is_success;
        if (!$response->is_success) {
            # something went wrong
            print STDERR "Manual check needed on $search_url\n";
            $sites_results{$site}{$search_term} = '0*';
            $timeouts{$site}++;
        }

        # if the site has a different message for no matches we first check for this
        #   eg 'no results for your search, 40000 for a similar search'
        if ($sites{$site}{'no_results_regex'} =~ /\w+/ && 
            $response->decoded_content((charset => 'UTF-8')) =~ 
                            m/$sites{$site}{'no_results_regex'}/){
            print STDERR "No results!\n";
            $sites_results{$site}{$search_term} = "0*";
        
        # otherwise, we just use whatever the number of results listed is
        #   eg 'total 0 results', 'total 5 results'.
        } elsif ($response->decoded_content((charset => 'UTF-8')) =~ m/$sites{$site}{'results_regex'}/) {
            $sites_results{$site}{$search_term} = $1;
            $sites_results{$site}{$search_term} = 0 if $sites_results{$site}{$search_term} > 5000;
        } 
        
         if ($sites_results{$site}{$search_term}) {
            print "$sites_results{$site}{$search_term}\n";
        } else {
            print "0\n";
        }
    }
}
close (FILE);

# print the results in a nice format
# specify utf8 instead of ascii
print "\n\nall results:\n";
binmode(STDOUT, ":utf8");
print "Artist\tRelease\t";

foreach my $site (sort keys %sites_results) {
    print "$site\t";
}
print "\n";

foreach my $search_term (@search_terms) {

    # print the artist
    #$search_term =~ s/\"//g;
    next if $search_term =~ /#/;
    my $search_term_print = $search_term;
    $search_term_print =~ s/,/\t/;
    print "$search_term_print\t";
    print "All\t" if $search_term !~ /,/;

    # and the result
    foreach my $site (sort keys %sites_results) {
        if ($sites_results{$site}{$search_term}) {
            print "$sites_results{$site}{$search_term}\t";
            } else {
                print "0\t";
            }
    }
    print "\n";
}
print "0* means site timeout\n";
print "www.site.com* means that the website is a meta-search engine\n";

