#======================================================================
# Re-make lecture materials.
#======================================================================

# Directories.
SITE = _site
INSTALL = $(HOME)/sites/software-carpentry.org/v5
LINKS = /tmp/bc-links
CACHED = .

# Templates for nbconvert and Pandoc.
IPYNB_TPL = _templates/ipynb.tpl

# Temporary book file.
BOOK_MD = ./book.md

# Principal target files.
INDEX = $(SITE)/index.html

# Jekyll configuration file.
CONFIG = _config.yml

# Directives.
.INTERMEDIATE : $(BOOK_MD)

#----------------------------------------------------------------------
# Specify the default target before any other targets are defined so
# that we're sure which one Make will choose.
#----------------------------------------------------------------------

all : commands

#----------------------------------------------------------------------
# Extra files the site depends on.
#----------------------------------------------------------------------

EXTRAS = \
	$(wildcard css/*.css) \
	$(wildcard css/*/*.css) \
	$(wildcard novice/*/img/*.png) \
	$(wildcard novice/*/img/*.svg)

#----------------------------------------------------------------------
# Create Markdown versions of IPython Notebooks in CACHED directory.
# This is currently the same as the source directory so that files
# will be in the right places after Jekyll converts them.
# ----------------------------------------------------------------------

# IPython Notebooks (split by directory so that they can be
# interpolated into other variables later on).
IPYNB_SRC_PYTHON = \
	$(sort $(wildcard novice/python/??-*.ipynb)) \
	$(sort $(wildcard intermediate/python/??-*.ipynb))
IPYNB_SRC_SQL = \
	$(sort $(wildcard novice/sql/??-*.ipynb))

# Notebooks converted to Markdown.
IPYNB_TX_PYTHON = $(patsubst %.ipynb,$(CACHED)/%.md,$(IPYNB_SRC_PYTHON))
IPYNB_TX_SQL = $(patsubst %.ipynb,$(CACHED)/%.md,$(IPYNB_SRC_SQL))

# Convert a .ipynb to .md.
$(CACHED)/%.md : %.ipynb $(IPYNB_TPL)
	ipython nbconvert --template=$(IPYNB_TPL) --to=markdown --output="$(subst .md,,$@)" "$<"

#----------------------------------------------------------------------
# Build everything with Jekyll.
#----------------------------------------------------------------------

# Book source (in Markdown).  These are listed in the order in which
# they appear in the final book-format version of the notes, and
# include Markdown files generated by other tools from other formats.
BOOK_SRC = \
	intro.md \
	team.md \
	novice/shell/index.md $(sort $(wildcard novice/shell/??-*.md)) \
	novice/git/index.md $(sort $(wildcard novice/git/??-*.md)) \
	novice/python/index.md $(IPYNB_TX_PYTHON) \
	novice/sql/index.md $(IPYNB_TX_SQL) \
	novice/extras/index.md $(sort $(wildcard novice/extras/??-*.md)) \
	novice/teaching/index.md  $(sort $(wildcard novice/teaching/??-*.md)) \
	novice/ref/index.md  $(sort $(wildcard novice/ref/??-*.md)) \
	bib.md \
	gloss.md \
	rules.md \
	LICENSE.md

# All source pages (including things not in the book).
PAGES_SRC = \
	contents.md \
	$(wildcard novice/capstones/*/*.md) \
	$(wildcard intermediate/python/*.md) \
	$(BOOK_SRC)

# Build the temporary input for the book by concatenating relevant
# sections of Markdown files, patching glossary references and image
# paths, and then running the whole shebang through Jekyll at the same
# time as everything else.
$(BOOK_MD) : $(PAGES_SRC) bin/make-book.py
	python bin/make-book.py $(BOOK_SRC) > $@

# Convert from Markdown to HTML.  This builds *all* the pages (Jekyll
# only does batch mode), and erases the SITE directory first, so
# having the output index.html file depend on all the page source
# Markdown files triggers the desired build once and only once.
$(INDEX) : $(BOOK_MD) $(CONFIG) $(EXTRAS)
	jekyll -t build -d $(SITE)
	rm -rf $(SITE)/novice/*/??-*_files

#----------------------------------------------------------------------
# Targets.
#----------------------------------------------------------------------

## commands : show all commands.
commands :
	@grep -E '^##' Makefile | sed -e 's/## //g'

## site     : build the site as GitHub will see it.
site : $(INDEX)

## install  : install on the server.
install : $(INDEX)
	rm -rf $(INSTALL)
	mkdir -p $(INSTALL)
	cp -r $(SITE)/* $(INSTALL)
	mv $(INSTALL)/contents.html $(INSTALL)/index.html

## contribs : list contributors (uses .mailmap file).
contribs :
	git log --pretty=format:%aN | sort | uniq

## fixme    : find places where fixes are needed.
fixme :
	@grep -i -n FIXME $$(find novice -type f -print | grep -v .ipynb_checkpoints)

## clean    : clean up all generated files.
clean : tidy
	rm -rf $(SITE)

## tidy     : clean up odds and ends.
tidy :
	rm -rf \
	$$(find . -name '*~' -print) \
	$$(find . -name '*.pyc' -print)
