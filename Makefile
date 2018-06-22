#
# Makefile
#

# Service name in docker-compose.yml
SERVICE = blog

all: serve

image: docker/jekyll/Dockerfile
	docker-compose build

build: image
	docker-compose run --rm $(SERVICE) rake build
	docker-compose run --rm $(SERVICE) rake linter:ruby
	docker-compose run --rm $(SERVICE) rake linter:yaml
	docker-compose run --rm $(SERVICE) rake linter:markdown
	docker-compose run --rm $(SERVICE) rake proofer:local
	docker-compose run --rm $(SERVICE) rake proofer:remote

serve:
	docker-compose up

clean:
	rm -rf _site
	rm -rf docker/nginx/html

.PHONY: all image build serve
