GIT_DIR=~/.config/git

GIT_CONFIG=$(GIT_DIR)/config
GIT_CONFIG_LOCAL=$(GIT_CONFIG).local
GIT_IGNORE=$(GIT_DIR)/ignore
TMUXCONF=~/.tmux.conf
ZSHRC=~/.zshrc
ZSHRC_LOCAL=$(ZSHRC).local

CLAUDE=~/.local/bin/claude
NPM=~/.local/bin/npm
SANDBOX=~/.local/bin/sandbox

.PHONY: install
install: $(CLAUDE) $(GIT_CONFIG) $(GIT_IGNORE) $(NPM) $(SANDBOX) $(TMUXCONF) $(ZSHRC)

$(CLAUDE): bin/claude
$(GIT_IGNORE): .config/git/ignore | $(GIT_DIR)
$(NPM): bin/npm
$(SANDBOX): bin/sandbox

$(CLAUDE) $(GIT_IGNORE) $(NPM) $(SANDBOX):
	cp $^ $@

$(GIT_DIR):
	mkdir --parents $@

$(GIT_CONFIG): Makefile | $(GIT_DIR)
	echo "[include]" > $@
	echo "	path = $(PWD)/.config/git/config" >> $@
	echo "	path = $(GIT_CONFIG_LOCAL)" >> $@

$(TMUXCONF): Makefile
	echo "source-file $(PWD)/.tmux.conf" > $@
	echo "if-shell \"ls \$$BASE16_THEME \|| ls \$$BASE24_THEME\" \"source-file $(PWD)/.tmux.tinted.conf\"" >> $@

$(ZSHRC): Makefile
	echo "source $(PWD)/.zshrc" > $@
	echo "if [[ -f $(ZSHRC_LOCAL) ]]; then source $(ZSHRC_LOCAL); fi" >> $@
