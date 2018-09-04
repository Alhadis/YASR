yas2atom  = ./yas2atom.pl
manPage   = yas2atom.1

all: cson yas2atom.1

# Compile `snippets.cson` file
cson:
	path=$${CSON_FILE=snippets.cson}; \
	$(yas2atom) `find ./snippets -type f -name '*.yasnippet'` > $$path; \
	command -v cson2json 2>&1 >/dev/null && cson2json $$path >/dev/null

# Unused; added only for personal amusement
$(manPage): $(yas2atom)
	pod2man --utf8 $(yas2atom) > $@

# Wipe generated build targets
clean:
	rm -f snippets.cson
	rm -f $(manPage)

.PHONY: clean
