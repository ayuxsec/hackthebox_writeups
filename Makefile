default: push-all

push-all:
	git add -A
	git commit -m "make push"
	git push
