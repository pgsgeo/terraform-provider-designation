#!/bin/bash
set -ne

# Build the provider
go build -o terraform-provider-designation .

# Create a temporary directory for the schema
mkdir -p tmp

# Generate the schema using tofu with dev_overrides
# We need to tell tofu where to find our locally built provider
cat > tmp/dev_overrides.tfrc <<EOF
provider_installation {
  dev_overrides {
    "pgsgeo/designation" = "$(pwd)"
  }
  direct {}
}
EOF

export TF_CLI_CONFIG_FILE="$(pwd)/tmp/dev_overrides.tfrc"

# Create a dummy main.tf to satisfy tofu init requirement (even though we skip init)
# actually with dev_overrides we don't need init, just providers schema
# But we need a provider block for it to know about the provider
cat > tmp/main.tf <<EOF
terraform {
  required_providers {
    designation = {
      source = "pgsgeo/designation"
    }
  }
}
provider "designation" {}
EOF

# Generate schema
cd tmp
tofu providers schema -json > ../provider-schema.json
cd ..

# Run tfplugindocs with the generated schema
go run github.com/hashicorp/terraform-plugin-docs/cmd/tfplugindocs generate --providers-schema=provider-schema.json

# Cleanup
rm -rf tmp
rm provider-schema.json terraform-provider-designation
