# Personal Blog

[![Build Status](https://github.com/morazow/blog.morazow.com/actions/workflows/ci.yml/badge.svg)](https://github.com/morazow/blog.morazow.com/actions/workflows/ci.yml)
[![Deploy Status](https://github.com/morazow/blog.morazow.com/actions/workflows/deploy.yml/badge.svg)](https://github.com/morazow/blog.morazow.com/actions/workflows/deploy.yml)

This repository contains source files for [personal blog][blog] of [m.orazow][morazow].

[blog]: https://blog.morazow.com
[morazow]: https://morazow.com

## Local Development

Requires Docker. The image matches the CI environment (Ruby 3.2, Bundler 2.4.18).

```sh
make build  # build the site into _site/
make serve  # serve at http://localhost:4000 with auto-regeneration
make clean  # remove generated files (_site, .jekyll-cache)
```
