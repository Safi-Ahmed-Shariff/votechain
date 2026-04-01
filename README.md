# ⛓ VoteChain

> India's first biometric-authenticated, post-quantum encrypted,
> zero-knowledge blockchain voting system.

## The Problem
India's voting system has no cryptographic privacy guarantee.
Booth capturing, ghost voting, and EVM tampering are real threats
affecting 900 million voters.

## The Solution
VoteChain uses 8 security layers to make electoral fraud
mathematically impossible — not just difficult.

## Architecture
```
Voter → Biometric Gate → ZK Proof Engine → Encrypted Vote → Blockchain
           ↓                    ↓                  ↓
      SHA3-512 Hash      Groth16 SNARK      Kyber-1024 PQC
      (identity never    (vote valid,       (quantum-proof
       stored raw)        who? unknown)      encryption)
```

## Microservices
| Service | Language | Port | Role |
|---|---|---|---|
| biometric-service | Python/FastAPI | 8001 | Fingerprint+iris hashing |
| auth-service | Go | 8002 | Eligibility + ZK proof |
| vote-service | Node.js | 8003 | Encrypted vote submission |
| tally-service | Python | 8004 | Homomorphic count |
| anomaly-detector | Python | 8005 | Claude API threat detection |
| frontend | React | 3000 | Voter + officer UI |

## DevOps Stack
Docker · Kubernetes (Minikube/EKS) · Terraform · Jenkins ·
GitHub Actions · Prometheus · Grafana · ELK Stack ·
HashiCorp Vault · Falco · Grype · OWASP ZAP

## Security Layers
1. 🔍 Dual biometric gate (fingerprint + iris, liveness detection)
2. ⬡  Post-quantum encryption (CRYSTALS-Kyber-1024)
3. ◎  Zero-Knowledge Proofs (Groth16 zk-SNARK)
4. ∑  Homomorphic tally (counted while encrypted)
5. ⛓  28-node Hyperledger Fabric (one per Indian state)
6. ▣  HSM key storage (FIPS 140-3 Level 4)
7. ◉  AI anomaly detection (Claude API)
8. ◷  Citizen-verifiable audit trail

## Quick Start
```bash
git clone git@github.com:YOUR_USERNAME/votechain.git
cd votechain
docker compose up --build
```

## Build Log
🔨 Building in public — Day 1/30
Follow progress: [https://www.linkedin.com/in/safi-ahmed-shariff-b03499264]

## Author
Safi | DevOps & Cloud Engineer
AWS Certified Cloud Practitioner
