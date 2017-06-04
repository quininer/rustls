TESTS=api badssl bugs client_suites curves errors features server_suites topsites
EXAMPLES=tlsclient tlsserver bench bogo_shim trytls_shim
BINARIES=lib $(addprefix example-, $(EXAMPLES)) $(addprefix test-, $(TESTS))
#RUNNABLES=$(addprefix run-test-, $(TESTS)) run-test-rustls
RUNNABLES=run-test-badssl

RUSTC_COV_OPTIONS=-Ccodegen-units=1 -Clink-dead-code -Cpasses=insert-gcov-profiling -Zno-landing-pads -L/usr/lib/llvm-3.8/lib/clang/3.8.1/lib/linux/ -lclang_rt.profile-x86_64
LCOVOPTS=--gcov-tool ./admin/llvm-gcov --rc lcov_branch_coverage=1 --rc lcov_excl_line=assert

all: covhtml

clean:
	cargo clean
	rm -rf *.gcda *.gcno run-test-*

lib:
	cargo rustc --all-features --profile test --lib
	RUSTFLAGS="$(RUSTC_COV_OPTIONS)" cargo rustc --all-features --profile test --lib

example-%: lib
	RUSTFLAGS="$(RUSTC_COV_OPTIONS)" cargo rustc --all-features --profile dev --example $*

test-%: lib
	RUSTFLAGS="$(RUSTC_COV_OPTIONS)" cargo rustc --all-features --profile dev --test $*

run-test-%: $(BINARIES)
	./$(subst .d,,$(firstword $(wildcard target/debug/$*-*)))
	touch $@

merged.lcov: $(RUNNABLES)
	lcov $(LCOVOPTS) --capture --directory . --base-directory . -o $@

merged_crate.lcov: merged.lcov
	lcov $(LCOVOPTS) --extract $^ "$(PWD)/*" -o $@

covhtml: merged_crate.lcov
	genhtml --branch-coverage --demangle-cpp --legend $^ -o target/coverage/ --ignore-errors source
