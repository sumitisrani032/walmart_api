# Release Checklist

## Pre-Release

### Code Quality

* [ ] All tests pass
* [ ] Rubocop passes
* [ ] No failing CI jobs
* [ ] No TODO placeholders remain
* [ ] No debugging code remains
* [ ] No commented-out code remains

### Documentation

* [ ] README is up to date
* [ ] Public API examples are accurate
* [ ] Changelog is updated
* [ ] ADRs reflect current architecture

### Security

* [ ] No secrets committed
* [ ] No API keys committed
* [ ] No private keys committed
* [ ] Sensitive data filtered from logs

### Dependencies

* [ ] Dependencies reviewed
* [ ] No unnecessary dependencies added
* [ ] Dependency versions pinned appropriately

---

## Versioning

* [ ] Version number updated
* [ ] Changelog updated for release
* [ ] Breaking changes documented

---

## Packaging

* [ ] Bundle install succeeds
* [ ] Gem builds successfully

```bash
gem build walmart_api.gemspec
```

* [ ] Gem installs successfully from local package

```bash
gem install ./walmart_api-x.y.z.gem
```

---

## Git

* [ ] All changes committed
* [ ] Main branch up to date
* [ ] Release tag created

Example:

```bash
git tag v0.1.0
git push origin v0.1.0
```

---

## RubyGems

* [ ] Authentication verified
* [ ] Gem pushed successfully

```bash
gem push walmart_api-x.y.z.gem
```

---

## Post Release

* [ ] GitHub release created
* [ ] Release notes published
* [ ] Next version milestone created
* [ ] Future roadmap reviewed
