#
# Makefile
#

NAME = blog

all: serve

build: Dockerfile
	docker-compose run --rm $(NAME) build
	docker-compose run --rm --entrypoint htmlproofer $(NAME) ./_site --url-ignore /linkedin\.com/

serve:
	docker-compose up

.PHONY: all build serve
