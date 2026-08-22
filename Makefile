.PHONY: all lint package index clean sync-schema

CHARTS_DIR ?= charts/
DIST := dist/charts
SCHEMA := values.schema.json

# Default value for CHILD_CHARTS is set to a shell command that finds all directories in CHARTS_DIR
# This can be overridden by passing CHILD_CHARTS="chart1 chart2" to the make command
CHARTS ?= $(shell ls -d $(CHARTS_DIR)/*/ | xargs -n 1 basename)

# Location of Repo
HELM_REPO ?= https://media-servarr.shw.al/charts

# Default target
build: package pre-fetch index

# Copy the root values.schema.json into each subchart so tooling (helm lint,
# helm package, artifact hub) can find it alongside the chart's values.yaml.
sync-schema:
	@echo "Syncing $(SCHEMA) into each chart..."
	$(foreach chart,$(CHARTS), cp $(SCHEMA) "$(CHARTS_DIR)$(chart)/$(SCHEMA)";)

# Lint the Helm charts
lint:
	@echo "Linting charts..."
	helm lint .
	$(foreach chart,$(CHARTS),helm lint "$(CHARTS_DIR)$(chart)";)

# Test the Helm charts
test:
	@$(foreach chart,$(CHILD_CHARTS),helm test $(chart) &&) echo "Helm tests completed."

# Package the Helm charts
package: sync-schema
	@echo "Packaging charts..."
	$(foreach chart,$(CHARTS), helm package "$(CHARTS_DIR)$(chart)" --dependency-update --destination $(DIST);)

# Fetch existing index for new package merge
pre-fetch:
	@echo "Fetching existing index.yaml..."
	curl -o $(DIST)/index.yaml $(HELM_REPO)/index.yaml

# Create index file for Helm repository
index:
	@echo "Generating index.yaml..."
	helm repo index --url $(HELM_REPO) --merge ./$(DIST)/index.yaml $(DIST)

# Clean up packages
clean:
	@echo "Cleaning up..."
	rm -vr $(DIST)

