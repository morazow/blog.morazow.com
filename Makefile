#
# Makefile
#

NS = morazow
REPO = blog
NAME = blog
PORTS = -p 4000:4000
VOLUMES = -v "$$PWD":/tmp/blog

all: build run

build: Dockerfile
	docker build --rm --force-rm -t $(NS)/$(REPO) .

run: build
	docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(NS)/$(REPO) 

rm:
	docker rm -f $(NAME)

.PHONY: all build run
