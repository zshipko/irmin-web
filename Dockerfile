# irmin-web

FROM ocaml/opam2:alpine as base
RUN sudo apk add --update m4 gmp gmp-dev perl
RUN git -C /home/opam/opam-repository pull

WORKDIR /src
ENV OPAMYES 1
RUN opam update
RUN opam pin add ke.dev --dev
RUN opam pin add encore --dev
RUN opam pin add git.dev --dev
RUN opam pin add git-http.dev --dev
RUN opam pin add git-unix.dev --dev
RUN opam pin add irmin.dev --dev
RUN opam pin add irmin-mem.dev --dev
RUN opam pin add irmin-fs.dev --dev
RUN opam pin add irmin-http.dev --dev
RUN opam pin add irmin-git.dev --dev
RUN opam pin add irmin-graphql.dev https://github.com/mirage/irmin.git
RUN opam pin add irmin-unix.dev --dev
RUN opam pin add irmin-web.dev https://github.com/zshipko/irmin-web.git

FROM alpine
ENV IRMIN_WEB_ROOT .
RUN adduser -D irmin
WORKDIR /home/irmin
USER irmin
EXPOSE 8080
COPY --from=base /home/opam/.opam/4.07/bin/irmin-web .
COPY $IRMIN_WEB_ROOT/* /home/irmin/static/
ENTRYPOINT ["./irmin-web", "-p", "8080", "-a", "0.0.0.0", "-s", "git", "-c", "string", "--root", "./data", "./static"]

