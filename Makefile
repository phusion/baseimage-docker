NAME = phusion/baseimage
VERSION = 0.11

.PHONY: all build test tag_latest release ssh

all: build_amd64 build_armhf

build_amd64:
	docker build -t $(NAME):$(VERSION) --rm image -f image-amd64/Dockerfile

build_armhf:
	docker run --rm --privileged multiarch/qemu-user-static:register --reset
	docker build -t $(NAME):$(VERSION)-armhf --rm image -f image-armhf/Dockerfile

test:
	env NAME=$(NAME) VERSION=$(VERSION) ./test/runner.sh
	env NAME=$(NAME) VERSION=$(VERSION)-armhf ./test/runner.sh

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest
	docker tag $(NAME):$(VERSION)-armhf $(NAME):armhf-latest

release: test tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)
	docker push $(NAME)-armhf
	@echo "*** Don't forget to create a tag by creating an official GitHub release."

ssh:
	chmod 600 image/services/sshd/keys/insecure_key
	@ID=$$(docker ps | grep -F "$(NAME):$(VERSION)" | awk '{ print $$1 }') && \
		if test "$$ID" = ""; then echo "Container is not running."; exit 1; fi && \
		IP=$$(docker inspect $$ID | grep IPAddr | sed 's/.*: "//; s/".*//') && \
		echo "SSHing into $$IP" && \
		ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i image/services/sshd/keys/insecure_key root@$$IP

test_release:
	echo test_release
	env

test_master:
	echo test_master
	env
