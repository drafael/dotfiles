# Git host authentication

Bootstrap installs Git, Git LFS, GitHub CLI (`gh`), and GitLab CLI (`glab`). Ubuntu uses the current `glab` Snap because Ubuntu 24.04's archive contains an older CLI; bootstrap grants the Snap access to SSH keys and the desktop keyring. Omarchy keeps its lazy `gh` launcher and installs `glab` through `omarchy pkg add`.

## GitHub

The tracked `.gitconfig` rewrites GitHub pushes to SSH. Run the interactive login and select or create an SSH key when prompted:

```sh
gh auth login --git-protocol ssh
gh auth status
ssh -T git@github.com
```

A successful SSH test reports that GitHub authenticated the key. GitHub does not provide shell access, so the command can still return a nonzero status.

## GitLab.com

Authenticate `glab`, select SSH as the Git protocol, and verify the configured host:

```sh
glab auth login --hostname gitlab.com --git-protocol ssh
glab auth status --hostname gitlab.com
ssh -T git@gitlab.com
```

Unlike the GitHub settings in this repository, the global Git configuration does not rewrite GitLab URLs. Use an SSH remote or clone with `glab repo clone` when SSH is required.

## Self-managed GitLab

Use the instance's hostname for an interactive login:

```sh
glab auth login --hostname gitlab.example.com --git-protocol ssh
glab auth status --hostname gitlab.example.com
ssh -T git@gitlab.example.com
```

When you run `glab auth login` inside an existing repository, `glab` can detect GitLab hosts from its remotes.

If the API or SSH endpoint uses a different hostname, provide it explicitly:

```sh
glab auth login \
  --hostname gitlab.example.com \
  --api-host api.gitlab.example.com \
  --api-protocol https \
  --ssh-hostname ssh.gitlab.example.com \
  --git-protocol ssh
```

Use `--api-host` only when the API endpoint differs from the Git remote host. Configure custom SSH ports in the Git remote URL or `~/.ssh/config`.

### Personal access tokens

If the self-managed instance does not provide OAuth for `glab`, create a personal access token with at least `api` and `write_repository` scopes. Pass it through standard input rather than placing it on the command line:

```sh
glab auth login \
  --hostname gitlab.example.com \
  --git-protocol ssh \
  --stdin < /path/to/token-file
```

Delete the temporary token file after login. Environment variables such as `GITLAB_TOKEN` are preferable for CI and other non-interactive environments.

## SSH keys

Create an Ed25519 key only when the workstation does not already have a suitable key:

```sh
ssh-keygen -t ed25519 -C "YOUR EMAIL"
cat ~/.ssh/id_ed25519.pub
```

Add the public key to each Git host that should accept it. A self-managed GitLab instance exposes the SSH key page at:

```text
https://gitlab.example.com/-/user_settings/ssh_keys
```

Use host entries in `~/.ssh/config` when different accounts or instances need different keys.

## Credential storage

Both CLIs prefer the operating system's credential store. If no keyring is available, `gh` or `glab` can fall back to plaintext configuration. `glab` uses `~/.config/glab-cli/config.yml` by default. Review the location reported by the authentication status command and protect plaintext token files.

For a self-managed instance with a private certificate authority, add that authority to the operating system's trust store. Do not bypass TLS verification to make login succeed.

## References

- [GitHub CLI authentication](https://cli.github.com/manual/gh_auth_login)
- [GitLab CLI installation options](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/installation_options.md)
- [GitLab CLI login](https://docs.gitlab.com/cli/auth/login/)
- [GitLab CLI authentication](https://docs.gitlab.com/cli/authentication/)
