GITCONFIG=~/.gitconfig
GITIGNORE=~/.gitignore
TMUXCONF=~/.tmux.conf
ZSHRC=~/.zshrc
ZSHRC_LOCAL=$(ZSHRC).local

CLAUDE=~/.local/bin/claude
NPM=~/.local/bin/npm
SANDBOX=~/.local/bin/sandbox

.PHONY: install
install: $(CLAUDE) $(GITCONFIG) $(GITIGNORE) $(NPM) $(SANDBOX) $(TMUXCONF) $(ZSHRC)

$(GITCONFIG):
	echo "[include]" > $@
	echo "	path = $(PWD)/.gitconfig" >> $@

$(CLAUDE): bin/claude
$(GITIGNORE): .gitignore
$(NPM): bin/npm
$(SANDBOX): bin/sandbox

$(CLAUDE) $(GITIGNORE) $(NPM) $(SANDBOX):
	cp $^ $@

$(TMUXCONF): Makefile
	echo "source-file $(PWD)/.tmux.conf" > $@
	echo "if-shell \"ls \$$BASE16_THEME \|| ls \$$BASE24_THEME\" \"source-file $(PWD)/.tmux.tinted.conf\"" >> $@

$(ZSHRC): Makefile
	echo "source $(PWD)/.zshrc" > $@
	echo "if [[ -f $(ZSHRC_LOCAL) ]]; then source $(ZSHRC_LOCAL); fi" >> $@
