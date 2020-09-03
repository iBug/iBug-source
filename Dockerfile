FROM ruby:2.7

WORKDIR /site
COPY Gemfile /site/
RUN bundle install --jobs=4 --retry=3 && \
    mkdir -p /image/ /site/_site/ && \
    git -C /image/ init && \
    git -C /image/ remote add origin https://github.com/iBug/image.git && \
    ln -s /image/ /site/_site/image
