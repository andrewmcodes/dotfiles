# Ruby & Rails

## Resources

https://sourabhbajaj.com/mac-setup/Ruby/

## Gems

```bash
gem install bundler
gem install rails
gem install solargraph
gem install rubocop
gem install rufo
gem install ruby-debug-ide
gem install debase
gem install shutup
gem install pry
```

### mysql2

Make sure `mysql` is installed with brew.

```bash
gem install mysql2 -v '0.5.3' -- --with-ldflags=-L/usr/local/opt/openssl/lib --with-cppflags=-I/usr/local/opt/openssl/include
```

### libxml-ruby

Make sure `libxml2` is installed with brew.

```bash
gem install libxml-ruby -v ‘3.1.0’ -- --with-xml2-config=/usr/local/opt/libxml2/bin/xml2-config --with-xml2-dir=/usr/local/opt/libxml2 --with-xml2-lib=/usr/local/opt/libxml2/lib --with-xml2-include=/usr/local/opt/libxml2/include
```
