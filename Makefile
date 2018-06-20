#
# Makefile
#

NAME = blog

all: serve

image: Dockerfile
	docker-compose build

build: image
	docker-compose run --rm $(NAME) rake build
	docker-compose run --rm $(NAME) rake linter:ruby
	docker-compose run --rm $(NAME) rake linter:yaml
	docker-compose run --rm --entrypoint htmlproofer $(NAME) ./_site --url-ignore /linkedin\.com/

serve:
	docker-compose up

clean:
	docker-compose run --rm $(NAME) rake jekyll:clean
	rm -rf _site

.PHONY: all image build serve
