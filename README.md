Yet Another Snippets Repository
===============================

Bunch of editor snippets in [YASnippet][1] format, shared between my [Emacs][2]
and [Atom][3] setups. I switch between the two quite frequently, and having a
<abbr title="Single Source of Truth">SSOT</abbr> for snippets makes them easier
to sync.


Usage
-----
These snippets are tailored to my personal workflow, and probably won't be of
much interest to you. However, you might find [`yas2atom.pl`][4] helpful if
you switch between Emacs and Atom on a regular basis. This is a Perl program
that generates the `snippets.cson` file Atom uses to store custom snippets.

To assemble the `.yasnippet` files into CSON, run:

~~~console
$ make cson && mv snippets.cson ~/.atom
~~~

Or if you'd like to compile snippets from another directory, use:

~~~console
$ ./yas2atom.pl /path/to/your/*.yasnippet > output.cson
~~~


Even if you don't use Emacs, you might prefer to store your snippets using
`.yasnippet` files instead of one huge CSON blob. [YAS's format][5] is based
upon TextMate's snippets, just like Atom's. The syntax is essentially the
same (but not 100%; see “Caveats” below)

For syntax highlighting, install the [`language-emacs-lisp`][6] package.


Caveats
-------
Some things to consider before forking this and adding your own snippets:

*	**Selectors must be specified in each file.**  
	This takes the form of an extra header field named `atom-selector`:

	~~~diff
	 # -*- mode: snippet -*-
	 # key: prefix
	+# atom-selector: .source.js
	 # --
	~~~

	If this field is absent, the snippet will be omitted from the compiled
	CSON file. This can be helpful if you port snippets from Atom packages,
	and you don't want pointless duplicates inflating your `snippets.cson`.

*	**Conversion isn't lossless.**  
	YASnippets is much more featureful than Atom's [snippet system][7].
	No attempts are made to convert or strip syntax it doesn't support
	(like embedded Lisp expressions).


[1]: http://joaotavora.github.io/yasnippet/
[2]: https://github.com/Alhadis/.files/tree/master/.emacs.d
[3]: https://github.com/Alhadis/.atom
[4]: ./yas2atom.pl
[5]: http://joaotavora.github.io/yasnippet/snippet-development.html
[6]: https://atom.io/packages/language-emacs-lisp
[7]: https://github.com/atom/snippets
