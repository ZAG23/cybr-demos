# Machine Identity Portfolio — Talk Track

## Before You Begin

**Audience:** Security architects, platform engineers, CISOs, DevOps/DevSecOps leads, AI/ML engineering teams.

**Core message:** CyberArk secures every type of machine identity — applications, infrastructure, certificates, cloud entitlements, and AI agents — from a single unified platform with one audit trail.

**Duration:** 20-30 minutes (full), 12-15 minutes (abbreviated — skip Steps 4b/4c/7).

**Tip:** The demo is interactive (press ENTER between steps). Use the pauses to narrate context and answer questions before advancing.

---

## Opening — Set the Scene

> *"Let me show you something. In most enterprises, the number of non-human identities — service accounts, API keys, certificates, and now AI agents — has already exceeded human identities. By 2027, analysts predict 10 unmanaged non-human identities for every human user. AI agents are the primary driver of that explosion."*
>
> *"I'm going to take a single workload — a containerized microservice and its AI agents — and walk it through every type of machine identity it needs to operate in a modern environment. Authentication, secrets, three different approaches to certificates, cloud-native secret sync, just-in-time infrastructure access, cloud entitlements, and AI agent identity governance. All from one platform, all in one workflow."*

**Press ENTER** — the banner appears with the scenario outline and your tenant/lab info.

> *"This is a real tenant — [point to tenant/lab line]. Everything you're about to see is hitting live CyberArk APIs. Nothing is mocked."*

If some optional stages aren't configured (e.g., no VCert API key, no K8s cluster), acknowledge it upfront:

> *"A few of the optional stages — like live Certificate Manager or cert-manager — will show in demo mode today. The code and configuration are identical; we just haven't wired up those backends for this environment."*

---

## Step 1: ISPSS Platform Authentication

**Key message:** One identity, one token, every service.

> *"Everything starts with identity. Our workload authenticates to CyberArk Identity Security Platform Shared Services — ISPSS — using a standard OAuth2 client_credentials flow. This is the same mechanism whether you're a microservice, a CI/CD pipeline, or an AI agent."*

**Press ENTER** — the curl command and token appear.

> *"We get back a bearer token. This single token is our passport to every CyberArk service: Privilege Cloud, Conjur, Secrets Hub, SIA, SCA, and the AI Gateway. One authentication event, one audit record, unified access."*

**Transition:**

> *"Now let's use that token to authenticate as a workload to Conjur Cloud."*

---

## Step 2: Conjur Cloud — Workload Authentication

**Key message:** Platform-native identity — no embedded credentials.

> *"Conjur Cloud is our Secrets Manager. But before we can retrieve any secrets, the workload needs to prove its identity. We exchange the ISPSS bearer token for a Conjur session token using OIDC authentication."*

**Press ENTER** — the curl command and Conjur token appear.

> *"Notice we didn't hard-code a Conjur API key anywhere. The workload used its platform identity — in this case an ISPSS service account — to authenticate. In production, this could be a Kubernetes service account JWT, an AWS IAM role, an Azure managed identity, or a GCP workload identity. Conjur supports all of them natively."*

**Pause for emphasis:**

> *"This is the foundation of zero-trust for machines. The workload's identity comes from its platform — not from a config file someone forgot to rotate."*

---

## Step 3: Conjur Cloud — Fetch Application Secrets

**Key message:** Secrets at runtime, never on disk.

> *"Now our workload retrieves the secrets it's authorized to access. We're fetching three: a database hostname, a database credential, and an API key."*

**Press ENTER** — three secrets appear, masked.

> *"You'll notice the values are masked in the output — that's intentional. In a real application, these values are injected into the runtime environment and never written to disk. The workload gets exactly the secrets its Conjur policy permits — nothing more."*

> *"Behind the scenes, these secrets originate in Privilege Cloud — CyberArk's vault. The Vault Synchronizer automatically syncs them to Conjur so workloads can consume them through a developer-friendly API without needing vault credentials."*

**If the audience is AI-focused:**

> *"This is actually a critical AI security control. LLMs memorize data they see in their context window. By fetching secrets at runtime — not embedding them in training data, RAG indexes, or agent configuration — we ensure the model can never memorize or disclose them, even under prompt injection. From an OWASP perspective, this directly addresses LLM06: Sensitive Information Disclosure."*

**If the audience is technical:**

> *"The access model here is identity-based RBAC. The Conjur policy defines which host identity can read which variables. If you try to access a secret you're not entitled to, you get a 403 — not a 404. The workload never even learns the secret exists."*

---

## Step 4a: Conjur Cloud PKI — Ephemeral Workload Certificates

**Key message:** Short-lived certs, zero CA infrastructure.

> *"Now we enter the certificate section. We're going to show three different approaches to certificate management, because the right answer depends on your workload type. Let's start with the simplest."*

> *"Conjur Cloud has a built-in PKI capability. Our workload requests a short-lived TLS certificate — in this case with a TTL of [point to TTL] seconds — using the same Conjur identity it already has. No separate CA infrastructure, no CSR workflow, no approval queue."*

**Press ENTER** — certificate details or capability overview appear.

If certificate was issued:

> *"There's our cert — [point to subject and dates]. Notice the validity window. This is a certificate that lives for minutes, not years. When it expires, the workload requests a new one. There's no revocation problem because there's nothing long-lived to revoke."*

If PKI is not configured:

> *"PKI isn't enabled on this tenant, but I can describe the flow. Conjur acts as a lightweight CA — the workload authenticates with its existing identity, requests a cert with a short TTL, and gets back a signed certificate and key. No ACME, no CSR approval — just an API call."*

> *"This is ideal for microservice-to-microservice mTLS, service mesh sidecars, and any workload where certificates should be ephemeral and high-volume."*

---

## Step 4b: VCert Python SDK — Full Certificate Lifecycle

**Key message:** Programmatic control for applications that manage their own certs.

> *"The second approach is the VCert SDK. This is for when your application needs to own its certificate lifecycle — request, retrieve, renew, and revoke — programmatically."*

> *"We're using the Python SDK here, but CyberArk provides Go, Java, and C++ SDKs as well. The backend is CyberArk Certificate Manager — the same platform that manages enterprise PKI, code signing, and SSH certificates."*

**Press ENTER** — the VCert lifecycle runs (or shows capability overview).

If running live:

> *"Watch the four phases: request submits a CSR to Certificate Manager, retrieve fetches the signed cert and chain, renew generates a fresh certificate with the same subject, and revoke invalidates the original. This is the full lifecycle in about 10 lines of Python."*

If in fake/demo mode:

> *"We're in demo mode since we don't have Certificate Manager credentials wired up, but the code is identical. In production, you'd set an API key for the SaaS service or TPP credentials for self-hosted, and the SDK handles the rest."*

> *"This approach is best for CI/CD pipelines that need to mint certs during deployment, non-Kubernetes applications, or any workload where the application itself is responsible for certificate management."*

---

## Step 4c: cert-manager + CyberArk Issuer — Kubernetes-Native

**Key message:** Declare what you need; Kubernetes handles the rest.

> *"The third approach is purely Kubernetes-native. If your workloads run on Kubernetes, you shouldn't have to write any certificate code at all."*

> *"We deploy a CyberArk Issuer into the cluster — this is a cert-manager CRD that connects to CyberArk Certificate Manager as the CA backend. Then we create a Certificate resource that declares what we need: common name, SANs, duration. cert-manager does the rest — it requests the cert, stores it in a Kubernetes Secret, and automatically renews it before expiry."*

**Press ENTER** — kubectl output shows Issuers, Certificates, and Secrets (or configuration overview).

If cluster is available:

> *"Here's our Issuer — [point to Ready status]. The Certificate resource is [Ready/Pending]. And the TLS secret contains tls.crt and tls.key, ready to be mounted into any pod. When this cert approaches expiry, cert-manager will automatically renew it — no human intervention, no cron job."*

If no cluster:

> *"We don't have a cluster connected today, but the manifests are here. It's three YAML files: an Issuer, a Certificate, and optionally a credential Secret. That's it."*

---

## Step 4 Comparison — Certificate Options Side by Side

**Key message:** Right tool for the right workload — all governed by CyberArk policy.

> *"Let me bring all three together so you can see the trade-offs."*

**Press ENTER** — the comparison table appears.

> *"Conjur PKI is your fastest path — API call, short-lived cert, done. Great for ephemeral workloads and service mesh.*

> *VCert SDK gives you full programmatic control — request, renew, revoke — and works on any platform, not just Kubernetes.*

> *cert-manager is zero-touch for Kubernetes teams — declare your cert in YAML and forget about it.*

> *The critical point: all three approaches are governed by CyberArk policy, produce auditable events, and tie back to a managed machine identity. You're not choosing between security and convenience — you get both."*

**This is a natural Q&A breakpoint.** Audience often asks about migration paths, which approach to start with, or how these compare to Let's Encrypt / Vault PKI.

---

## Step 5: Secrets Hub — Cloud-Native Secret Sync

**Key message:** Secrets where your workloads expect them, managed where your security team controls them.

> *"Shifting from certificates back to secrets — but now from the ops perspective. Secrets Hub solves a common problem: your security team manages credentials in CyberArk's vault, but your cloud-native workloads expect secrets in AWS Secrets Manager, Azure Key Vault, or GCP Secret Manager."*

> *"Secrets Hub bridges that gap. It syncs secrets from Privilege Cloud to your cloud-native stores automatically. Your developers use the cloud-native SDK they already know. Your security team keeps centralized control, rotation, and audit."*

**Press ENTER** — sync policies and secret stores appear.

If policies exist:

> *"We have [N] sync policies active. Each one maps a PAM safe to a cloud target — [point to source/target]. When a secret is rotated in Privilege Cloud, Secrets Hub pushes the new value to the target store within minutes."*

If no policies:

> *"We don't have Secrets Hub configured in this environment, but the concept is straightforward: create a target store, create a sync policy with a filter, and Secrets Hub handles the rest. Supported targets include AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, and HashiCorp Vault."*

> *"The key insight: you don't have to choose between centralized security and cloud-native developer experience. You get both."*

---

## Step 6: SIA — Just-in-Time SSH

**Key message:** No standing access, no permanent keys, just-in-time certificates.

> *"Now we move from workload identity to infrastructure access. Secure Infrastructure Access — SIA — eliminates standing SSH keys and permanent credentials on your servers."*

> *"Instead of distributing SSH keys and hoping someone rotates them, SIA issues short-lived SSH certificates on demand. A user or automation authenticates to CyberArk, requests access to a target, and gets a certificate that's valid for the duration of their session. When the session ends, the cert expires. There's nothing to revoke, nothing to rotate, and nothing left behind on the target."*

**Press ENTER** — SIA targets appear.

If targets exist:

> *"Here are our configured targets — [point to names and platforms]. Each one is accessible via JIT SSH certificates. No permanent keys on any of these machines."*

> *"SIA also supports just-in-time database access with strong accounts, session recording, and isolation. It's zero standing privilege for infrastructure — the same philosophy we apply to secrets and certificates."*

---

## Step 7: SCA — Just-in-Time Cloud Entitlements

**Key message:** Eliminate persistent cloud admin credentials.

> *"SCA extends the same zero-standing-privilege model to cloud permissions. Instead of giving a developer a persistent AWS PowerUser role, SCA provisions a time-bounded session — they get the access they need for the task, and it automatically revokes when the window closes."*

**Press ENTER** — access policies appear.

> *"This supports AWS, Azure, and GCP. You define access policies with approval workflows, time limits, and scope. The user requests elevation, gets approved (or auto-approved for lower-risk roles), and CyberArk provisions the session. Full audit trail, automatic revocation, no forgotten admin accounts."*

If no policies:

> *"We don't have SCA policies configured today, but the model is the same as SIA: just-in-time, time-bounded, fully audited. The goal is eliminating every persistent privileged credential in your cloud environment."*

---

## Step 8: Secure AI Agents — Agentic Identity Lifecycle

**Key message:** AI agents are the newest type of machine identity — and they need the same governance.

> *"This is the newest addition to the portfolio, and arguably the most important one looking forward. AI agents — whether they're GitHub Copilot, Claude, custom LLM agents, or agentic workflows — are proliferating across enterprises. Each one is a non-human identity — often completely unmanaged — with API keys, IAM roles, and network access. This is the 2025 version of the unmanaged service account problem, at 10x the scale and 100x the speed. Each one needs an identity, each one accesses sensitive resources, and each one needs to be governed — using the same rigor you'd apply to human privileged access."*

> *"CyberArk's Secure AI Agents treats each AI agent as a first-class identity on the platform. You register the agent, it gets a unique client ID and client secret, and it authenticates through a dedicated gateway URL. From that point on, CyberArk policy governs what the agent can access — just like any other machine identity."*

**Press ENTER** — registered agents and details appear.

If agents exist:

> *"Here are our registered agents — [point to names, types, and states]. Each one has its own identity and lifecycle state. You can see the type — COPILOT, CLAUDE, or CUSTOM — and the current state. Agents move through a lifecycle: registered, pending connection, active, and can be suspended instantly if there's a concern."*

> *"Let me show you the detail on this agent — [point to detail output]. It has its own client ID, tags for classification, and a creation timestamp. Every action this agent takes through the CyberArk gateway is audited."*

If no agents:

> *"We don't have any agents registered in this environment yet, but the registration is a single API call — name, type, description, callback URL. You get back credentials and a gateway URL. The agent uses those to authenticate and access resources through CyberArk's AI Gateway."*

**AI Gateway / MCP section:**

> *"The AI Gateway is how agents actually access tools and resources. It uses the Model Context Protocol — MCP — to proxy agent tool calls through CyberArk-secured endpoints."*

**Press ENTER** (if applicable) — MCP server inventory appears.

> *"Think of it this way: instead of giving an AI agent direct database credentials, you register an MCP server in the gateway — say, a SIA DB MCP server for database access. The agent calls the gateway, the gateway authenticates the agent, checks policy, and proxies the request. The agent never sees raw credentials. If you need to cut off access, you suspend the agent identity — one action, immediate effect."*

> *"This is actually a critical defense against two of the top OWASP risks for LLM applications. First, prompt injection — if an attacker manages to redirect the agent's behavior, they can't exfiltrate credentials the agent never had. Second, excessive agency — the gateway enforces what tools and data each agent can access, so even a compromised agent is contained to its permitted scope."*

**Least Privilege for Agents — What Policy Really Means (optional deep dive):**

If the audience is security-focused, walk through the layers:

> *"When we say 'CyberArk policy governs access,' here's what that enforces in practice. Seven layers: (1) Cloud IAM — per-agent roles scoped to exactly the services needed. (2) Tool access — the agent can only call tools it's configured for, no shell, no read-any-file. (3) MCP connections — each external system uses separate, scoped credentials. (4) Model access — limited to specific model IDs. (5) Data access — task-scoped, not all data all the time. (6) Network access — the agent reaches only the endpoints it needs. (7) Delegation — when agents delegate to other agents, that delegation is scoped to the specific task, not a pass-through of full permissions. Even if one layer is breached, the others contain the blast radius."*

> *"This is governed by two roles: Secure AI Admins for full administration, and Secure AI Builders for teams that are registering and configuring agents."*

---

## Summary — Bring It All Together

**Press ENTER** — the summary table appears.

> *"Let's step back and look at what we just did."*

> *"We took a single workload and walked it through nine CyberArk capabilities — all on one platform, all sharing one identity fabric, all feeding one audit trail."*

**Point to the summary table and walk down the rows:**

> *"Platform auth. Workload secrets. Three approaches to certificates — each right for a different workload type. Secrets synced to cloud-native stores. Just-in-time SSH. Just-in-time cloud roles. And AI agent governance."*

**Point to the Certificate Strategy section:**

> *"On certificates specifically — this is a question I get a lot — the answer is: use all three. Conjur PKI for your ephemeral microservice certs, VCert SDK for your CI/CD pipelines and non-K8s apps, cert-manager for your Kubernetes workloads. They all tie back to CyberArk Certificate Manager for policy and audit."*

**Point to the Identity Types Secured section:**

> *"And notice the identity types: applications, infrastructure, and now AI agents. These are the three pillars of machine identity, and CyberArk secures all of them from one platform."*

**What "one audit trail" really means (optional for compliance-focused audiences):**

> *"That unified audit trail isn't just CloudTrail entries. It's five layers of attribution: (1) Identity and session — which agent, which credential, who invoked it. (2) Tool and API calls — what the agent did and what the result was. (3) Data access — what was read, written, or deleted, with volume and classification. (4) Business context — why the agent took that action. (5) Delegation — if this agent told another agent to do something, that's fully traceable. From a compliance perspective — EU AI Act Article 12, SOC 2, HIPAA, PCI-DSS — you can now answer: 'Show me everything Agent X did on Tuesday, why it did it, what it accessed, and what it told other agents to do.' Most enterprises can't answer that today."*

**Closing statement:**

> *"The question isn't whether your organization has machine identities — you have thousands, maybe millions. The question is whether they're secured, governed, and auditable. What we just showed you is a single platform that handles all of it — secrets, certificates, infrastructure access, cloud entitlements, and AI agent identities — with zero standing privileges and a unified audit trail."*
>
> *"And critically, this works whether your agents run on AWS, Azure, GCP, on-premises, or across multiple clouds. Cloud-native solutions like AWS Bedrock Guardrails or Azure Managed Identity work great — until your agents leave that cloud boundary. CyberArk is cloud-agnostic. One identity platform for every type of machine identity, everywhere."*

---

## Handling Common Questions

| Question | Suggested Response |
|---|---|
| "How does this compare to HashiCorp Vault?" | "Vault is a secrets engine — it's great at what it does, and we integrate with it via Secrets Hub. CyberArk is a broader identity security platform: we add certificate lifecycle, JIT infrastructure access, cloud entitlements, AI agent governance, and enterprise vault capabilities. Many customers run both — Vault as a dev-facing store, CyberArk as the security control plane." |
| "What about Let's Encrypt / ACME?" | "ACME is a protocol for domain-validated certs. CyberArk Certificate Manager provides organization-validated and extended-validation certs with enterprise policy, approval workflows, and integration with internal CAs. For public web endpoints, ACME is fine. For internal PKI, enterprise compliance, and code signing — you need a managed certificate platform." |
| "Do we need all nine components?" | "No — the platform is modular. Most customers start with secrets management (Conjur) or vault (Privilege Cloud) and expand. Each component adds value independently but they're stronger together because they share identity and policy." |
| "What's the AI agent story for on-prem models?" | "Same model. CUSTOM agent type covers any LLM deployment — cloud-hosted, on-prem, or hybrid. The agent registers with CyberArk, gets an identity, and routes through the AI Gateway regardless of where it runs." |
| "How does certificate rotation work in production?" | "Conjur PKI: re-request on expiry (typically automated in the workload). VCert SDK: call renew_cert() — your app or automation decides when. cert-manager: fully automatic — the controller renews before expiry based on the Certificate resource's renewBefore field." |
| "What's the deployment footprint?" | "ISPSS, Conjur Cloud, Secrets Hub, SIA, SCA, and Secure AI Agents are all SaaS — no infrastructure to deploy. VCert SDK is a pip/go/maven dependency. cert-manager runs in your K8s cluster (one Helm install). The only on-prem component is the Vault Synchronizer for Conjur, and that's a lightweight connector." |
| "We're all-in on AWS — why not just use Bedrock Guardrails + IAM?" | "Guardrails are content filters, not identity controls. And what about your Azure agents? Your on-prem agents? Your third-party SaaS agents? AWS IAM only covers AWS. CyberArk gives you one identity platform across every cloud, every runtime, every agent type." |
| "What about OWASP Top 10 for LLMs?" | "CyberArk directly addresses 4 of the top 10: LLM01 (Prompt Injection) — secrets never in the context window. LLM06 (Sensitive Information Disclosure) — vault-first architecture. LLM08 (Excessive Agency) — 7-layer least privilege. LLM09 (Overreliance) — full audit trail for every agent action. The remaining 6 are complemented by LLM Guard and network controls." |
| "How does this compare to what we already have for human PAM?" | "Same platform, same depth. Your security team already has CyberArk for human identities — session recording, credential rotation, JIT access. Secure AI Agents extends that exact model to every agent: unique identity, scoped credentials, time-bounded access, full audit. No new platform to learn." |

---

## Abbreviated Flow (12-15 minutes)

If time is tight, run Steps 1-4a, then skip to 5, 6, 8, and Summary:

| Step | Time | What to Show |
|------|------|--------------|
| 1 - ISPSS Auth | 1 min | One token, every service |
| 2 - Conjur Auth | 1 min | Platform-native identity |
| 3 - Secrets | 2 min | Runtime secret retrieval |
| 4a - Conjur PKI | 2 min | Ephemeral certs (mention 4b/4c exist) |
| 4 comparison table | 1 min | Three options at a glance |
| 5 - Secrets Hub | 2 min | Cloud-native sync |
| 8 - Secure AI | 3 min | Newest and highest-interest topic |
| Summary | 2 min | Tie it all together |

Skip 4b (VCert SDK), 4c (cert-manager), 6 (SIA), and 7 (SCA) — mention them by name during the summary.

---

## Executive-Only Flow (5-7 minutes)

For CISO or board-level audience, skip the terminal entirely. Use the summary table as a slide and narrate:

> *"CyberArk secures nine categories of machine identity from one platform. [Walk the table.] The three things that matter to you: first, zero standing privileges — every access is just-in-time and time-bounded. Second, one audit trail — every machine identity action across every component feeds the same audit. Third, AI readiness — as your teams deploy AI agents, those agents are governed by the same identity platform as your applications and infrastructure."*
