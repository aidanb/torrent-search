# torrent-search
A Perl script to easily determine the number search results for a list of artists and releases over torrent sites.

The script will search for all artists listed in the file 'searches'. Each site you wish to search should be listed in 'sites.csv'

The script performs no validation of the search results, so you should perform a manual check initially so you understand the type of results a particular search term will return.

searches
This file should contain a list of artists and nothing else, eg:
ARTIST 1
ARTIST 2
ETC

The script will also search for individual releases, delineated by a comma:
ARTIST 1, RELEASE 1
ARTIST 1, RELEASE 2


sites.csv
There are seven sites in the file already, they were the most popular torrent indexers when I was writing this.
[title], [search url], [regex to match and capture number of results], [regex for zero results]
Use an * to indicate the position of the search term in the url.
Ensure there is no overlap between results regex and no results regex.
No results regex takes precedence as some sites will show something like 'X results found from similar search terms", so we then check if there was a term indicating none for the original search 
If the number of results regex is standard (ie something like 'x torrents found' for both zero and non-zero results, just leave the zero-results-regex blank
Try to specify a search for music torrents only for best results.
