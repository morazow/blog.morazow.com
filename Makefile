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
	docker-compose run --rm $(NAME) rake linter:markdown
	docker-compose run --rm $(NAME) rake proofer:local
	docker-compose run --rm $(NAME) rake proofer:remote

serve:
	docker-compose up

clean:
	docker-compose run --rm $(NAME) rake jekyll:clean
	rm -rf _site

.PHONY: all image build serve
