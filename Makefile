NAME = phusion/baseimage
VERSION = 0.9.0

.PHONY: all build tag_latest

all: build

build:
	docker build -t $(NAME):$(VERSION) -rm image

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest
