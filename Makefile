NAME = phusion/baseimage
VERSION = 0.9.0

.PHONY: all build tag_latest release

all: build

build:
	docker build -t $(NAME):$(VERSION) -rm image

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

release: tag_latest
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
