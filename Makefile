GITCONFIG=~/.gitconfig
GITIGNORE=~/.gitignore
TMUXCONF=~/.tmux.conf
ZSHRC=~/.zshrc
ZSHRC_LOCAL=$(ZSHRC).local

.PHONY: install
install: $(GITCONFIG) $(GITIGNORE) $(TMUXCONF) $(ZSHRC)

$(GITCONFIG):
	echo "[include]" > $@
	echo "	path = $(PWD)/.gitconfig" >> $@

$(GITIGNORE): .gitignore
	cp $^ $@

$(TMUXCONF): Makefile
	echo "source-file $(PWD)/.tmux.conf" > $@
	echo "if-shell \"ls $$BASE16_THEME\" \"source-file $(PWD)/.tmux.base16.conf\"" >> $@

$(ZSHRC): Makefile
	echo "source $(PWD)/.zshrc" > $@
	echo "if [[ -f $(ZSHRC_LOCAL) ]]; then source $(ZSHRC_LOCAL); fi" >> $@
