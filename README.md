## Welcome to the Faraone Lab Website Repository

This website is built with [Quarto](https://quarto.org/), an open source scientific and technical publishing system.

## Notes to self

### Adding publications

use `just newpub` for creation of new directory and input prompts for new record.

### Adding new people

use `just newperson` for creation of new directory and input prompts for new record.

### Deployment

-   use long-running `updates` branch for deploy previews

-   `quarto render` locally and include `_site` in version control

-   GitHub action `scp-to-server.yml` deploys to server
