export

SHELL = /bin/bash
PYTHON = python3
PIP = pip3
LOG_LEVEL = INFO
PYTHONIOENCODING=utf8

# pytest args. Set to '-s' to see log output during test execution, '--verbose' to see individual tests. Default: '$(PYTEST_ARGS)'
PYTEST_ARGS =

# Docker container tag
DOCKER_TAG = 'ocrd/tesserocr'

# BEGIN-EVAL makefile-parser --make-help Makefile

help:
	@echo ""
	@echo "  Targets"
	@echo ""
	@echo "    deps-ubuntu   Dependencies for deployment in an ubuntu/debian linux"
	@echo "                  (lib*-dev merely for building tesserocr with pip)"
	@echo "                  (tesseract-ocr: Ubuntu 18.04 now ships 4.0.0,"
	@echo "                   but some beta, not the final release,"
	@echo "                   on which tesserocr 2.4.0 depends;"
	@echo "                   this downloads a tesseract build from git"
	@echo "                   and installs it system-wide -"
	@echo "                   intended for dockerfile and travis,"
	@echo "                   not recommended for live systems!)"
	@echo "    deps          Install python deps via pip"
	@echo "    deps-test     Install testing python deps via pip"
	@echo "    install       Install"
	@echo "    docker        Build docker image"
	@echo "    test          Run test"
	@echo "    test-cli      Test the command line tools"
	@echo "    repo/assets   Clone OCR-D/assets to ./repo/assets"
	@echo "    test/assets   Setup test assets"
	@echo "    assets-clean  Remove symlinks in test/assets"
	@echo ""
	@echo "  Variables"
	@echo ""
	@echo "    PYTEST_ARGS  pytest args. Set to '-s' to see log output during test execution, '--verbose' to see individual tests. Default: '$(PYTEST_ARGS)'"
	@echo "    DOCKER_TAG   Docker container tag"

# END-EVAL

# Dependencies for deployment in an ubuntu/debian linux
# (lib*-dev merely for building tesserocr with pip)
# (tesseract-ocr: Ubuntu 18.04 now ships 4.0.0,
#  but some beta, not the final release,
#  on which tesserocr 2.4.0 depends;
#  this downloads a tesseract build from git
#  and installs it system-wide -
#  intended for dockerfile and travis,
#  not recommended for live systems!)
deps-ubuntu:
	apt-get install -y \
		git \
		python3 \
		python3-pip \
		libtesseract-dev \
		libleptonica-dev \
		tesseract-ocr-eng \
		tesseract-ocr \
		wget
	wget -O - https://github.com/nijel/tesseract-ocr-build/releases/download/4.0.0-1/tesseract.tar.xz | tar -xJf -
	cp -rt /usr .tesseract/*

# Install python deps via pip
deps:
	$(PIP) install -r requirements.txt

# Install testing python deps via pip
deps-test:
	$(PIP) install -r requirements_test.txt

# Install
install:
	$(PIP) install .

# Build docker image
docker:
	docker build -t $(DOCKER_TAG) .

# Run test
test: test/assets
	# declare -p HTTP_PROXY
	$(PYTHON) -m pytest test $(PYTEST_ARGS)

# Test the command line tools
test-cli: test/assets
	$(PIP) install -e .
	rm -rfv test-workspace
	cp -rv test/assets/kant_aufklaerung_1784 test-workspace
	export LC_ALL=C.UTF-8; cd test-workspace/data && \
		ocrd-tesserocr-segment-region -l DEBUG -m mets.xml -I OCR-D-IMG -O OCR-D-SEG-BLOCK ; \
		ocrd-tesserocr-segment-line   -l DEBUG -m mets.xml -I OCR-D-SEG-BLOCK -O OCR-D-SEG-LINE ; \
		ocrd-tesserocr-recognize      -l DEBUG -m mets.xml -I OCR-D-SEG-LINE -O OCR-D-TESS-OCR

.PHONY: test test-cli install deps deps-ubuntu deps-test help

#
# Assets
#

# Clone OCR-D/assets to ./repo/assets
repo/assets:
	mkdir -p $(dir $@)
	git clone https://github.com/OCR-D/assets "$@"


# Setup test assets
test/assets: repo/assets
	mkdir -p $@
	cp -r -t $@ repo/assets/data/*

.PHONY: assets-clean
# Remove symlinks in test/assets
assets-clean:
	rm -rf test/assets
