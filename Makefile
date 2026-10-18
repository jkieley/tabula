APP_DIR ?= $(HOME)/Applications
BIN_DIR ?= $(HOME)/.local/bin
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister
# CommandLineTools lacks the SwiftUIMacros plugin (needed for @State on the macOS 27 SDK).
export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

.PHONY: build test app install uninstall clean

build:
	swift build

test:
	swift test

app:
	./scripts/build-app.sh

install: app
	pkill -x Tabula || true
	rm -rf "$(APP_DIR)/Tabula.app"
	ditto build/Tabula.app "$(APP_DIR)/Tabula.app"
	mkdir -p "$(BIN_DIR)"
	ln -sf "$(APP_DIR)/Tabula.app/Contents/Helpers/tabula" "$(BIN_DIR)/tabula"
	$(LSREGISTER) -f "$(APP_DIR)/Tabula.app"

uninstall:
	rm -f "$(BIN_DIR)/tabula"
	rm -rf "$(APP_DIR)/Tabula.app"

clean:
	rm -rf .build build
