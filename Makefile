IMAGE := blog.morazow.com

.PHONY: image build serve clean

image:
	docker build --tag $(IMAGE) .

build: image
	docker run --rm --volume $(PWD):/site $(IMAGE) build

serve: image
	docker run --rm --interactive --tty --volume $(PWD):/site --publish 4000:4000 $(IMAGE) \
		serve --host 0.0.0.0 --force_polling

clean:
	rm -rf _site .jekyll-cache
