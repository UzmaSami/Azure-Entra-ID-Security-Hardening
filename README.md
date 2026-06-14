# 🔐 Azure-Entra-ID-Security-Hardening


## Architecture
![Architecture](docs/architecture-diagram.png)


## Overview

This project documents the design and
implementation of enterprise-grade identity
security across a hybrid Microsoft Entra ID
environment using Azure AD Premium P2.

Identity is the new perimeter. The
traditional security model assumed that
everything inside the corporate network
could be trusted. That model collapsed
when cloud adoption, remote working, and
mobile devices dissolved the network
boundary entirely. Today an organisation's
most valuable assets — data, applications,
infrastructure — are accessed through
identity. Whoever controls identity
controls access to everything.

This project hardens that identity layer
using the full capability of Azure AD
Premium P2 — Conditional Access, Privileged
Identity Management, Identity Protection,
and Access Reviews — transforming a basic
cloud directory into an active security
control that evaluates, enforces, and
adapts to risk in real time.

---

## The Problem This Solves

A default Azure AD tenant is not secure.
It is functional. There is an important
difference.

Out of the box, Azure AD allows users to
authenticate from any location, any device,
at any time, using only a password. Legacy
authentication protocols that cannot
enforce MFA remain enabled. Privileged
roles are permanently assigned — an
administrator who is granted Global
Administrator retains that access
indefinitely whether they are actively
using it or not. There is no automated
response to risky sign-in behaviour.
There is no mechanism to review whether
access grants made six months ago are
still appropriate.

This default configuration is the reason
that identity-based attacks — credential
stuffing, password spray, phishing,
business email compromise — account for
the majority of cloud security incidents.
The attack surface is enormous and largely
undefended.

Azure AD Premium P2 provides the tooling
to close these gaps systematically. This
project implements all of it.

---

## Why Identity Security Starts with
## Conditional Access

Before implementing any other identity
security control the question to answer
is: under what conditions should access
be granted?

Conditional Access is Microsoft's
policy engine for answering that
question. It evaluates signals — who
is signing in, from where, on what
device, to what application, at what
risk level — and makes an access
decision based on policies you define.

The critical architectural insight is
that Conditional Access should be
designed as a set of policies that
work together rather than as individual
rules. A common mistake is creating a
single policy that tries to do
everything. The result is a brittle
configuration where one change breaks
unintended scenarios and the blast
radius of misconfiguration is large.

I designed five policies with distinct
purposes that complement each other.
The MFA policy handles the baseline
authentication requirement. The legacy
authentication policy handles protocol
risk. The risk-based policy handles
anomalous behaviour. The device
compliance policy handles the endpoint
trust question. The admin policy handles
the highest-privilege scenario with
maximum enforcement.

Each policy can be modified independently.
Each failure mode is contained. This is
how Conditional Access should be
architected.

---

## The Case for Privileged Identity
## Management

Permanent privileged role assignments
are one of the highest risk
configurations in any Azure environment.

Consider the attack scenario. An
adversary compromises the credentials
of a Global Administrator. Because
that administrator's role is permanently
assigned, the adversary immediately
has Global Administrator access. There
is no additional barrier. No approval
step. No time limit. No notification
that the role is being used outside
normal patterns.

PIM fundamentally changes this model.
Privileged roles become eligible rather
than active. An administrator who needs
to perform a privileged action must
explicitly request role activation,
provide a business justification, and
in the case of the highest-privilege
roles receive approval from a second
administrator. The activation is time-
limited — it expires automatically.
Every activation generates an audit
event. Every activation triggers a
notification.

For an adversary who has compromised
an account, this model dramatically
increases the cost of the attack. They
cannot silently operate with global
administrator access indefinitely.
Any attempt to activate a privileged
role requires justification, may
require approval, and generates
visible alerts.

The operational objection to PIM is
always friction. Administrators who
are accustomed to permanent access
resist the additional steps. This
objection reflects a misunderstanding
of what those additional steps cost
versus what they protect against. A
few seconds of friction for legitimate
administrators is an enormous barrier
for adversaries.

---

## Identity Protection and Risk-Based
## Access Control

Conditional Access policies that
require MFA from all users from all
locations are a significant improvement
over password-only authentication.
They are not sufficient on their own.

Identity Protection adds a risk
evaluation layer that detects
behavioural anomalies and threat
signals that static Conditional Access
policies cannot. When a user who
normally authenticates from London
suddenly authenticates from a different
country minutes later — impossible
travel — Identity Protection raises
the sign-in risk score. When credentials
associated with that user's account
appear in a breach database, the user
risk score is raised.

These risk scores feed directly into
Conditional Access. A sign-in scored
as high risk is blocked regardless of
whether MFA was completed. Completing
MFA does not make a high-risk sign-in
safe — an adversary who has both the
password and the MFA token still
represents a compromised account.
The correct response to high risk is
blocking and investigation, not
additional authentication factors.

This is the distinction between
Conditional Access as an authentication
control and Conditional Access as a
risk-based access control. The latter
is a more mature and more effective
security model.

---

## The Break-Glass Account Design

Every Conditional Access deployment
requires break-glass accounts — emergency
access accounts that are excluded from
all Conditional Access policies and all
MFA requirements.

This is not a security weakness. It is
a security requirement.

If the MFA system fails, if the Identity
Protection service has an outage, if
a Conditional Access misconfiguration
locks out all administrators — without
break-glass accounts the organisation
loses all ability to manage its Azure
environment. The cure becomes worse
than the disease.

Break-glass accounts must be:
permanently excluded from all
Conditional Access policies, secured
with extremely long randomly generated
passwords stored in a physical safe,
configured without MFA registration
so they cannot be locked out by MFA
failures, monitored with alerts that
trigger immediately on any sign-in
since legitimate use should be
extremely rare, and reviewed regularly
to confirm the credentials are known
and accessible to the appropriate
people.

I implemented two break-glass accounts
with monitoring alerts configured in
Sentinel — any authentication using
these accounts generates a Priority 1
alert regardless of time of day.

---

## Security Defaults vs Conditional Access

Microsoft provides Security Defaults
as a baseline identity security
configuration for tenants that have
not configured Conditional Access.
Security Defaults enable MFA for all
users, block legacy authentication,
and protect privileged roles with
additional requirements.

Security Defaults are appropriate for
organisations with no dedicated security
resource and no complex access
requirements. They are not appropriate
for a mature hybrid environment with
specific compliance requirements,
break-glass account needs, and
risk-based access control objectives.

Security Defaults cannot be customised.
They cannot exclude accounts. They
cannot integrate with Identity
Protection risk scores. They cannot
be scoped to specific applications
or conditions.

When Conditional Access is configured,
Security Defaults must be disabled —
the two cannot coexist. This is not
a downgrade. Replacing Security
Defaults with a well-designed
Conditional Access policy set is a
significant security improvement
provided the policy set covers at
minimum the same scenarios Security
Defaults address. I validated this
coverage before disabling Security
Defaults.

---

## Access Reviews — Closing the
## Stale Access Problem

Identity security is not only about
controlling what access is granted
at the point of authentication. It
is also about ensuring that access
granted in the past remains
appropriate today.

People change roles. Contractors
finish engagements. Projects end.
Business relationships evolve. In
each of these situations access that
was appropriate at the time of grant
may no longer be appropriate. Without
a mechanism to identify and remove
stale access it accumulates over time
creating an ever-expanding pool of
dormant access rights that represent
attack surface.

Access Reviews automate the process
of periodically asking the right
people — resource owners, managers,
the users themselves — whether access
remains appropriate. Reviews can be
configured to auto-deny access that
is not actively confirmed, removing
the default-retain behaviour that
allows stale access to persist
indefinitely.

I configured quarterly reviews for
privileged roles and monthly reviews
for guest users — two categories where
stale access risk is highest and the
consequences of inappropriate access
are most severe.

---

## Implementation Decisions

### Report-Only Mode for New Policies

All Conditional Access policies were
initially deployed in report-only mode.
Report-only mode evaluates the policy
and records what the outcome would have
been without enforcing it. This allows
validation that the policy behaves as
expected — that the right users are
affected, that break-glass accounts are
correctly excluded, that no unexpected
scenarios are blocked — before enforcement
creates operational impact.

Moving policies from report-only to
enabled after validation is a discipline
that prevents the most common
Conditional Access failure mode:
a misconfigured policy that locks
users out of their accounts.

### Named Locations

Conditional Access policies that
reference location conditions require
named locations — defined IP ranges
or countries that represent trusted
and untrusted network zones.

I defined the NADRA London office
IP range as a trusted named location.
This allows policies to differentiate
between authentication from the known
corporate network and authentication
from unknown external locations —
enabling different enforcement levels
for each scenario without treating
all external access as equally risky.

### MFA Methods

MFA registration was configured to
allow Microsoft Authenticator app,
FIDO2 security keys, and as a fallback,
phone SMS. The preference order is
intentional. The Authenticator app
provides phishing-resistant MFA because
the approval is number-matched — the
user must confirm a number displayed
on the sign-in screen matches a number
displayed in the app. SMS MFA is
retained as a fallback but is the
weakest method and SIM-swapping attacks
can defeat it. A mature implementation
eventually removes SMS entirely.

---

## Challenges Encountered

*Synced account behaviour in PIM*

Accounts synced from on-premises Active
Directory via Azure AD Connect behave
differently in PIM than cloud-only
accounts. Specifically password writeback
and some PIM activation flows interact
in ways that require careful testing.
I validated PIM activation and
deactivation for synced accounts
separately from cloud-only accounts
to confirm consistent behaviour.

**Conditional Access and legacy
application compatibility**

Several applications in the environment
used legacy authentication protocols
that cannot support MFA. The policy
to block legacy authentication initially
broke these applications. I resolved
this by identifying each application,
evaluating whether it could be updated
to support modern authentication, and
where it could not, implementing
service account-based access with
certificate authentication as an
alternative to password-based legacy
protocol access. The legacy
authentication block was then
enforced with no exceptions.

*Identity Protection risk calibration*

The initial Identity Protection
deployment flagged a significant number
of sign-ins as medium risk due to
unfamiliar sign-in properties — users
authenticating from devices and
locations that had not previously
been seen. This is expected behaviour
during initial deployment as Identity
Protection builds its baseline model.
I set the risk policies to audit mode
for the first two weeks and monitored
the risk detections to distinguish
genuine anomalies from baseline-
building noise before enabling
enforcement.

---

## Lessons Learned

The most significant lesson from this
project was that identity security
requires an understanding of the
business context in which it operates.

Conditional Access policies that are
technically correct can still fail
operationally if they do not account
for legitimate business workflows.
A policy that blocks external access
without excluding the sales team who
works externally every day will
generate support calls, workarounds,
and eventually pressure to weaken
the policy.

Effective identity security requires
mapping the legitimate access patterns
in the organisation before defining
what should be blocked. The policies
should be designed around reality and
then exceptions should be challenged
and minimised — not the other way
around.

The second lesson was about the
relationship between PIM and
operational culture. PIM is not
just a technical control. It changes
how administrators work. Introducing
it without communication, training,
and clear guidance on the activation
process creates resistance that
undermines adoption. Technical
implementation is the easy part.
Change management is where identity
security projects succeed or fail.

---

## What I Would Do Differently at Scale

At enterprise scale I would implement
Conditional Access through a formal
policy naming convention and version
control system — storing policy
definitions as JSON in a Git repository
and deploying changes through an
approval workflow rather than making
changes directly in the portal. Policy
drift and undocumented changes are
a significant operational risk in
mature Conditional Access deployments.

I would also implement Continuous
Access Evaluation — a feature that
allows Azure AD to revoke access
tokens in near-real-time when risk
conditions change, rather than waiting
for token expiry. In a standard
deployment a compromised token remains
valid until it expires — potentially
hours. With CAE the session can be
terminated within minutes of a risk
signal being detected.

Authentication Strengths would replace
the current MFA requirement with a
more granular control — requiring
phishing-resistant MFA specifically
for privileged operations rather than
any MFA method, eliminating the
scenario where a user completes SMS
MFA and accesses a highly sensitive
resource.

---


Uzma Shabbir
Azure Security Engineer | AZ-104 | AZ-500
[GitHub](https://github.com/UzmaSami) •
[LinkedIn](https://linkedin.com/in/uzma-shabbir-034361128)
