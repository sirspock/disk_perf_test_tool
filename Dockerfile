FROM python:3.4-onbuild
CMD ["python" "-m" "wally" "test" 'my test comment' "configs-examples/hdd.yaml"]