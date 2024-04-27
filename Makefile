.PHONY: %

default:
	bundle exec rake

%:
	bundle exec rake $@
