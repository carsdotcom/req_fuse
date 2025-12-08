## What

Describe what this PR does. What does it change? How does it generally work? Unless getting into deep technical details is necessary, this should be a high-level introduction for the reviewer.

## Why

What is driving this change? Is it a bug fix? New feature? Dependency upgrade? Refactoring?

- Avoid using URLs here that aren't universally accessible or reasonably future-proof.

## Jira ticket

Please add a link to the Jira work ticket, if applicable.

## Steps to Validate/Verify

What needs to be done locally to validate this change? Include any specific test commands or scenarios to run.

```bash
mix test
```

## Additional Notes

What are other things to consider about this PR? Are there breaking changes? Will consuming applications need to update their usage?

## After merge checklist:

- [ ] Update version in `mix.exs` if releasing a new version
- [ ] Update `CHANGELOG.md` with changes
- [ ] Create and push a new git tag if releasing: `git tag -a X.Y.Z -m "vX.Y.Z" && git push origin X.Y.Z`
- [ ] Check [GitHub Actions](https://github.com/carsdotcom/req_fuse/actions) to make sure CI passes
