GITCONFIG=~/.gitconfig
GITIGNORE=~/.gitignore
SANDBOX=~/.local/bin/sandbox
TMUXCONF=~/.tmux.conf
ZSHRC=~/.zshrc
ZSHRC_LOCAL=$(ZSHRC).local

.PHONY: install
install: $(GITCONFIG) $(GITIGNORE) $(SANDBOX) $(TMUXCONF) $(ZSHRC)

$(GITCONFIG):
	echo "[include]" > $@
	echo "	path = $(PWD)/.gitconfig" >> $@

$(GITIGNORE): .gitignore
$(SANDBOX): bin/sandbox
	cp $^ $@

$(TMUXCONF): Makefile
	echo "source-file $(PWD)/.tmux.conf" > $@
	echo "if-shell \"ls \$$BASE16_THEME \|| ls \$$BASE24_THEME\" \"source-file $(PWD)/.tmux.tinted.conf\"" >> $@

$(ZSHRC): Makefile
	echo "source $(PWD)/.zshrc" > $@
	echo "if [[ -f $(ZSHRC_LOCAL) ]]; then source $(ZSHRC_LOCAL); fi" >> $@
