# ADR-0001: Use the Official GitHub Readme Stats Container

**Status:** Accepted

**Date:** 2026-07-16

## Context

GitHub Stats Platform is an infrastructure project whose purpose is to deploy and operate GitHub Readme Stats in a production-ready environment.

## Decision

The platform will deploy the upstream GitHub Readme Stats container image rather than maintaining a custom application Dockerfile.

## Rationale

- Reduces maintenance burden.
- Receives upstream updates.
- Keeps repository focused on infrastructure.
- Simplifies CI/CD.

## Consequences

### Positive

- Smaller codebase.
- Easier upgrades.
- Clear separation of responsibilities.

### Trade-offs

- Less control over application image contents.
- Dependent on upstream image availability.