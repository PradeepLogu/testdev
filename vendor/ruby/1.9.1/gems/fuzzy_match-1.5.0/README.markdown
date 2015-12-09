# fuzzy_match

Find a needle in a haystack based on string similarity and regular expression rules.

Replaces [`loose_tight_dictionary`](https://github.com/seamusabshere/loose_tight_dictionary) because that was a confusing name.

## Real-world usage

<p><a href="http://brighterplanet.com"><img src="https://s3.amazonaws.com/static.brighterplanet.com/assets/logos/flush-left/inline/green/rasterized/brighter_planet-160-transparent.png" alt="Brighter Planet logo"/></a></p>

We use `fuzzy_match` for [data science at Brighter Planet](http://brighterplanet.com/research) and in production at

* [Brighter Planet's impact estimate web service](http://impact.brighterplanet.com)
* [Brighter Planet's reference data web service](http://data.brighterplanet.com)

We often combine it with [`remote_table`](https://github.com/seamusabshere/remote_table) and [`errata`](https://github.com/seamusabshere/errata):

- download table with `remote_table`
- correct serious or repeated errors with `errata`
- `fuzzy_match` the rest

## Quickstart

    >> require 'fuzzy_match'
    => true
    >> FuzzyMatch.new(['seamus', 'andy', 'ben']).find('Shamus)
    => "seamus"

See also the blog post [Fuzzy match in Ruby](http://numbers.brighterplanet.com/2012/01/18/fuzzy-match-in-ruby/).

## Default matching (string similarity)

At the core, and even if you configure nothing else, string similarity (calculated by "pair distance" aka Dice's) is used to compare records.

You can tell `FuzzyMatch` what field or method to use via the `:read` option... for example, let's say you want to match a `Country` object like `#<Country name:"Uruguay" iso_3166_code:"UY">`

    >> matcher = FuzzyMatch.new(Country.all, :read => :name)  # Country#name will be called when comparing
    => #<FuzzyMatch: [...]>
    >> matcher.find('youruguay')
    => #<Country name:"Uruguay" iso_3166_code:"UY">            # the matcher returns a Country object

## Optional rules (regular expressions)

You can improve the default matchings with rules. There are 4 different kinds of rules. Each rule is a regular expression. Depending on the kind of rule, the results of running the regular expression are used for a particular purpose.

We suggest that you **first try without any rules** and only define them to improve matching, prevent false positives, etc.

    >> matcher = FuzzyMatch.new(['Ford F-150', 'Ford F-250', 'GMC 1500', 'GMC 2500'], :groupings => [ /ford/i, /gmc/i ], :normalizers => [ /K(\d500)/i ], :identities => [ /(f)-?(\d50)/i ])
    => #<FuzzyMatch: [...]> 
    >> matcher.find('fordf250')
    => "Ford F-250" 
    >> matcher.find('gmc truck k1500')
    => "GMC 1500" 

For identities and normalizers (see below), **only the captures are used.** For example, `/(f)-?(\d50)/i` captures the "F" and the "250" but ignores the dash. So place your parentheses carefully! Groupings work the same way, except that if you don't have any captures, a simple match will pass.

### Groupings

Group records together.

Setting a grouping of `/Airbus/` ensures that strings containing "Airbus" will only be scored against to other strings containing "Airbus". A better grouping in this case would probably be `/airbus/i`.

Formerly called "blockings," but that was jargon that confused people.

### Identities

Prevent impossible matches.

Adding an identity like `/(f)-?(\d50)/i` ensures that "Ford F-150" and "Ford F-250" never match.

Note that identities do not establish certainty. They just say whether two records **could** be identical... then string similarity takes over.

### Stop words

Ignore common and/or meaningless words. Applied before normalizers.

Adding a stop word like `THE` ensures that it is not taken into account when comparing "THE CAT", "THE DAT", and "THE CATT"

### Normalizers (formerly called tighteners)

Strip strings down to the essentials. Applied after stop words.

Adding a normalizer like `/(boeing).*(7\d\d)/i` will cause "BOEING COMPANY 747" and "boeing747" to be normalized to "BOEING 747" and "boeing 747", respectively. Since things are generally downcased before they are compared, these would be an exact match.

## Find options

* `read`: how to interpret each record in the 'haystack', either a Proc or a symbol
* `must_match_grouping`: don't return a match unless the needle fits into one of the groupings you specified
* `must_match_at_least_one_word`: don't return a match unless the needle shares at least one word with the match. Note that "Foo's" is treated like one word (so that it won't match "'s") and "Bolivia," is treated as just "bolivia"
* `first_grouping_decides`: force records into the first grouping they match, rather than choosing a grouping that will give them a higher score
* `gather_last_result`: enable `last_result`

## Case sensitivity

String similarity is case-insensitive. Everything is downcased before scoring. This is a change from previous versions.

Be careful when trying to use case-sensitivity in your rules; in general, things are downcased before comparing.

## String similarity algorithm

The algorithm is [Dice's Coefficient](http://en.wikipedia.org/wiki/Dice's_coefficient) (aka Pair Distance) because it seemed to work better than Longest Substring, Hamming, Jaro Winkler, Levenshtein (although see edge case below) etc.

Here's a great explanation copied from [the wikipedia entry](http://en.wikipedia.org/wiki/Dice%27s_coefficient):

    to calculate the similarity between:

        night
        nacht

    We would find the set of bigrams in each word:

        {ni,ig,gh,ht}
        {na,ac,ch,ht}

    Each set has four elements, and the intersection of these two sets has only one element: ht.

    Inserting these numbers into the formula, we calculate, s = (2 · 1) / (4 + 4) = 0.25.

### Edge case: when Dice's fails, use Levenshtein

In edge cases where Dice's finds that two strings are equally similar to a third string, then Levenshtein distance is used. For example, pair distance considers "RATZ" and "CATZ" to be equally similar to "RITZ" so we invoke Levenshtein.

    >> 'RITZ'.pair_distance_similar 'RATZ'
    => 0.3333333333333333 
    >> 'RITZ'.pair_distance_similar 'CATZ'
    => 0.3333333333333333                   # pair distance can't tell the difference, so we fall back to levenshtein...
    >> 'RITZ'.levenshtein_similar 'RATZ'
    => 0.75 
    >> 'RITZ'.levenshtein_similar 'CATZ'
    => 0.5                                  # which properly shows that RATZ should win

## Cached results

Make sure you add active\_record\_inline\_schema to your gemfile.

TODO write documentation. For now, please see how [we manually cache matches between aircraft and flight segments](https://github.com/brighterplanet/earth/blob/master/lib/earth/air/aircraft.rb).

## Glossary

The admittedly imperfect metaphor is "look for a needle in a haystack"

* needle: the search term
* haystack: the records you are searching (<b>your result will be an object from here</b>)

## Using amatch to make it faster

You can optionally use [`amatch`](http://flori.github.com/amatch/) by [Florian Frank](https://github.com/flori) (thanks Flori!) to make string similarity calculations in a C extension.

    require 'fuzzy_match'
    require 'amatch' # note that you have to require this... fuzzy_match won't require it for you
    FuzzyMatch.engine = :amatch

Otherwise, pure ruby versions of the string similarity algorithms derived from the [answer to a StackOverflow question](http://stackoverflow.com/questions/653157/a-better-similarity-ranking-algorithm-for-variable-length-strings) and [the text gem](https://github.com/threedaymonk/text/blob/master/lib/text/levenshtein.rb) are used. Thanks [marzagao](http://stackoverflow.com/users/10997/marzagao) and [threedaymonk](https://github.com/threedaymonk)!

## Authors

* Seamus Abshere <seamus@abshere.net>
* Ian Hough <ijhough@gmail.com>
* Andy Rossmeissl <andy@rossmeissl.net>

## Copyright

Copyright 2012 Brighter Planet, Inc.
