#
# Makefile
#

# Service name in docker-compose.yml
SERVICE = blog

all: serve

image: docker/jekyll/Dockerfile
	docker-compose build

build: rb md yml proof

serve:
	docker-compose up

# Linter tasks
rb: image
	docker-compose run --rm $(SERVICE) rake linter:ruby

md: image
	docker-compose run --rm $(SERVICE) rake linter:markdown

yml: image
	docker-compose run --rm $(SERVICE) rake linter:yaml

proof: image
	docker-compose run --rm $(SERVICE) rake build
	docker-compose run --rm $(SERVICE) rake proofer:local
	docker-compose run --rm $(SERVICE) rake proofer:remote

clean:
	rm -rf _site
	rm -rf docker/nginx/html

.PHONY: all image build serve
