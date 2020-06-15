docker_image = docker_developer_environment

help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

always:

##@ Docker Support

interactive-developer-environment-in-docker: ## Use docker for all dependencies - run make from there
	docker build -t $(docker_image) - < etc/developer.Dockerfile
	docker run -v $$PWD:/volume -w /volume -it $(docker_image)

##@ Development

target/debug/grit: always
	cargo build

target/release/grit: always
	cargo build --release

lint: ## Run lints with clippy
	cargo clippy

profile: target/release/grit ## run callgrind and annotate its output - linux only
	valgrind --callgrind-out-file=callgrind.profile --tool=callgrind  $< >/dev/null
	callgrind_annotate --auto=yes callgrind.profile

benchmark: target/release/grit ## see how fast things are, powered by hyperfine
	hyperfine '$<'

tests: check unit-tests journey-tests ## run all tests

check: ## Build all code in suitable configurations
	cargo check --all

unit-tests: ## run all unit tests
	cargo test --all --no-fail-fast

continuous-unit-tests: ## run all unit tests whenever something changes
	watchexec -w src $(MAKE) unit-tests

journey-tests: target/debug/grit ## run stateless journey tests
	./tests/stateless-journey.sh $<

continuous-journey-tests: ## run stateless journey tests whenever something changes
	watchexec $(MAKE) journey-tests

