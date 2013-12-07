SHELL=/bin/bash

S3_CMD=s3cmd -c .s3cfg -P
S3_SYNC=$(S3_CMD) sync --delete-removed
S3_BUCKET=library.tfes.org

all: index

index:
	find public/ -type d | while read d; do \
		[ "$$(echo -n "$$d" | tail -c 1)" = / ] || d="$${d}/"; \
		pushd "$$d"; \
		echo '<html>' >index.html; \
		echo '<head><title>Index of '"$${d/public/}"'</title></head>' >>index.html; \
		echo '<body bgcolor="white">' >>index.html; \
		echo '<h1>Index of '"$${d/public/}"'</h1><hr><pre><a href="../">../</a>' >>index.html; \
		for f in */; do \
			[ -d "$$f" ] || continue; \
			t="$$(date -u -d@"$$(stat -c%Y "$${f}")" '+%d-%b-%Y %H:%M')"; \
			s=-; \
			l="$$f"; \
			f="$$(echo "$$f" | sed 's,/$$,,' | perl -ne 'use URI::Escape; chomp($$_); print uri_escape($$_);')/"; \
			[ "$${#l}" -gt 50 ] && l="$$(echo "$$l" | head -c 47)..>"; \
			ls="$$((51-$${#l}))"; \
			ts="$$((37-$${#t}-$${#s}))"; \
			l="$$(echo "$$l" | perl -ne 'use HTML::Entities; chomp($$_); print encode_entities($$_);')"; \
			echo -n "<a href=\"$${f}\">$${l}</a>" >>index.html; \
			for i in $$(seq $$ls); do echo -n ' '; done >>index.html; \
			echo -n "$${t}" >>index.html; \
			for i in $$(seq $$ts); do echo -n ' '; done >>index.html; \
			echo -n "$${s}" >>index.html; \
			echo >>index.html; \
		done; \
		for f in *; do \
			[ '(' ! -d "$$f" -o ! -e "$$f" ')' -a "$$f" != index.html ] || continue; \
			t="$$(date -u -d@"$$(stat -c%Y "$${f}")" '+%d-%b-%Y %H:%M')"; \
			s="$$(stat -c%s "$${f}")"; \
			l="$$f"; \
			f="$$(echo "$$f" | perl -ne 'use URI::Escape; chomp($$_); print uri_escape($$_);')"; \
			[ "$${#l}" -gt 50 ] && l="$$(echo "$$l" | head -c 47)..>"; \
			ls="$$((51-$${#l}))"; \
			ts="$$((37-$${#t}-$${#s}))"; \
			l="$$(echo "$$l" | perl -ne 'use HTML::Entities; chomp($$_); print encode_entities($$_);')"; \
			echo -n "<a href=\"$${f}\">$${l}</a>" >>index.html; \
			for i in $$(seq $$ls); do echo -n ' '; done >>index.html; \
			echo -n "$${t}" >>index.html; \
			for i in $$(seq $$ts); do echo -n ' '; done >>index.html; \
			echo -n "$${s}" >>index.html; \
			echo >>index.html; \
		done; \
		echo '</pre><hr></body>' >>index.html; \
		echo '</html>' >>index.html; \
		popd; \
	done

publish: index
	$(S3_SYNC) public/ s3://$(S3_BUCKET)/

fetch:
	$(S3_SYNC) s3://$(S3_BUCKET)/ public/

.PHONY: all index publish fetch
