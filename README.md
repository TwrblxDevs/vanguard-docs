# Vanguard Documentation Site

This repository is the GitHub Pages site for the Vanguard Roblox framework documentation. It uses MkDocs Material and publishes a static, searchable reference site through GitHub Actions.

## Repository Setup

1. Create an empty GitHub repository, for example `vanguard-docs`.
2. Push this project to the repository's `main` branch.
3. Open **Settings > Pages** in GitHub.
4. Set the Pages source to **GitHub Actions**.
5. Run the **Deploy documentation** workflow or push a commit to `main`.

The workflow derives the repository name, repository URL, and Pages base URL automatically. It builds with strict validation and deploys the generated `site/` directory through GitHub's Pages artifact pipeline.

## Local Development

Create an isolated environment:

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --requirement requirements.txt
```

Start the live preview:

```powershell
mkdocs serve
```

Open `http://127.0.0.1:8000`.

Build exactly as CI does:

```powershell
mkdocs build --strict --site-dir site
```

## Synchronize Framework Documentation

The site keeps a publishable copy of the Markdown manuals from the sibling Vanguard source project.

```powershell
.\scripts\sync-docs.ps1
```

Default expected layout:

```text
Systems/
  MyFramework/
    docs/
  VanguardDocs/
    scripts/sync-docs.ps1
```

Use an explicit source when the repositories live elsewhere:

```powershell
.\scripts\sync-docs.ps1 -Source C:\path\to\Vanguard\docs
```

The script:

- maps every source `README.md` to a clean `index.md` route;
- updates relative README links to those routes;
- preserves site-only assets and configuration;
- does not delete files that exist only in the site repository.

After syncing, run the strict build before committing.

## Navigation

Navigation is explicitly maintained in `mkdocs.yml`. When a new manual is added to the framework, add its generated `index.md` path to `nav` after syncing.

## Branding

- Site colors and component styling: `docs/assets/stylesheets/extra.css`
- Small progressive-enhancement script: `docs/assets/javascripts/extra.js`
- Vanguard mark and favicon: `docs/assets/images/vanguard-mark.svg`

## Custom Domain

To use a custom domain, create `docs/CNAME` containing only the domain:

```text
docs.example.com
```

Then configure the same domain in GitHub Pages settings and update `SITE_URL` or the fallback `site_url` in `mkdocs.yml`.

## License

The documentation site and copied Vanguard documentation use the repository's MIT License.
