#
# Makefile
#

NAME = blog

all: serve

image: Dockerfile
	docker-compose build

build: image
	docker-compose run --rm $(NAME) build
	docker-compose run --rm --entrypoint htmlproofer $(NAME) ./_site --url-ignore /linkedin\.com/

serve:
	docker-compose up

.PHONY: all image build serve
