CLAUDE=~/.local/bin/claude
GITCONFIG=~/.gitconfig
GITIGNORE=~/.gitignore
SANDBOX=~/.local/bin/sandbox
TMUXCONF=~/.tmux.conf
ZSHRC=~/.zshrc
ZSHRC_LOCAL=$(ZSHRC).local

.PHONY: install
install: $(CLAUDE) $(GITCONFIG) $(GITIGNORE) $(SANDBOX) $(TMUXCONF) $(ZSHRC)

$(GITCONFIG):
	echo "[include]" > $@
	echo "	path = $(PWD)/.gitconfig" >> $@

$(CLAUDE): bin/claude
$(GITIGNORE): .gitignore
$(SANDBOX): bin/sandbox

$(CLAUDE) $(GITIGNORE) $(SANDBOX):
	cp $^ $@

$(TMUXCONF): Makefile
	echo "source-file $(PWD)/.tmux.conf" > $@
	echo "if-shell \"ls \$$BASE16_THEME \|| ls \$$BASE24_THEME\" \"source-file $(PWD)/.tmux.tinted.conf\"" >> $@

$(ZSHRC): Makefile
	echo "source $(PWD)/.zshrc" > $@
	echo "if [[ -f $(ZSHRC_LOCAL) ]]; then source $(ZSHRC_LOCAL); fi" >> $@
