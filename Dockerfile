FROM ruby:2.6

RUN git clone https://github.com/iBug/iBug-source.git /srv/iBug.github.io && \
cd /srv/iBug.github.io && bundle install

CMD ["/srv/iBug.githuh.io/script/entrypoint.sh"]
