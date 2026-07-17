# ADR-0001: Deployment Strategy

**Status**

Accepted

---

## Context

The objective of this repository is to provide a production-ready deployment template for GitHub Readme Stats.

Several architectural approaches were evaluated, including:

- Forking the upstream repository
- Embedding the application source directly
- Using Git submodules
- Building a deployment-only repository

The chosen approach should minimize maintenance overhead while remaining flexible and easy to update as the upstream project evolves.

---

## Decision

This repository will function exclusively as a deployment and operations project.

The GitHub Readme Stats application will remain an external upstream dependency.

The repository will provide:

- Docker configuration
- Docker Compose configuration
- Nginx reverse proxy configuration
- Deployment automation
- CI/CD workflows
- Operational documentation

Application source code will not be maintained within this repository.

---

## Rationale

Separating deployment from application source provides several benefits:

- Simplifies maintenance
- Avoids duplication of upstream code
- Reduces merge conflicts
- Enables easier upstream updates
- Keeps repository responsibilities clearly defined

This approach aligns with the project's objective of serving as a reusable deployment template rather than an application fork.

---

## Consequences

### Positive

- Clear separation of responsibilities
- Smaller repository footprint
- Easier maintenance
- Cleaner update process
- Better long-term scalability

### Negative

- Requires fetching the upstream application during deployment
- Dependent on upstream project availability

---

## Alternatives Considered

### Fork the upstream repository

Rejected due to ongoing maintenance overhead and the need to continually synchronize with upstream changes.

### Git submodule

Rejected because it increases repository complexity and introduces additional workflow considerations for contributors.

### Copy the application source

Rejected because it duplicates upstream code and complicates future updates.

---

## References

- Upstream GitHub Readme Stats project
- Repository architecture documentation