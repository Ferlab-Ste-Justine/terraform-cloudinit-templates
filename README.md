# About

This repo is the beginning of a refactoring attempt to isolate the reusable parts of our cloud-init orchestrations in order to improve legibility, reduce the amount of copy-pasting between our vm terraform modules and generally speed up terraform module creation and updates across applications and clouds.

# Structural Evolution

Currently, we are exploring having several terraform packages in a monorepo as it seems like it is supported and optimized for: https://developer.hashicorp.com/terraform/language/modules/sources#modules-in-package-sub-directories.

If it doesn't perform as expected, we might alternatively refer to this repo as a git submodule.

We contemplated using a separate git repo for each template, but currently don't want to incur the overhead of installing too many separate terraform modules just for cloudinit.

We also contemplated creating a provider instead, but it seems like over-engineering for something that can be comfortably solved by terraform modules.