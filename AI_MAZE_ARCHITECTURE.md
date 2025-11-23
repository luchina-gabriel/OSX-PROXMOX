# AI Maze Architecture - Hardened Infrastructure with Backstage Portal

**Version**: 1.0.0
**Created**: 2025-01-22
**Purpose**: Security-through-obscurity + Defense-in-depth using unconventional technology stack

---

## 🎯 Concept: The "AI Maze"

An infrastructure management portal that confuses automated crawlers, vulnerability scanners, and AI-powered reconnaissance tools by using an uncommon technology stack while providing a legitimate, user-friendly interface.

### Why It Works

1. **Signature Evasion**: Most scanners trained on LAMP/MEAN/JAMstack patterns
2. **Uncommon Stack**: Swift backend is rare for infrastructure tools
3. **Legitimate Tools**: Backstage is production-grade, not security theatre
4. **Defense in Depth**: Multiple layers with different technologies
5. **Confusion**: AI/ML models struggle with unexpected tech combinations

---

## 🏗️ Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                      PUBLIC INTERNET                             │
│                   (Automated Scanners/Crawlers)                  │
└──────────────────────────┬──────────────────────────────────────┘
                           ↓
                    [Firewall/WAF]
                    - Rate limiting
                    - GeoIP blocking
                    - DDoS protection
                           ↓
┌──────────────────────────────────────────────────────────────────┐
│  LAYER 1: Backstage Developer Portal (VM 400)                    │
│  ────────────────────────────────────────────────────────────────│
│  Technology: Node.js + React (TypeScript)                        │
│  Port: 7007 (non-standard, reverse proxied)                      │
│  IP: 192.168.100.40                                              │
│                                                                  │
│  Features:                                                       │
│  ✓ Service catalog (VMs, containers, infrastructure)            │
│  ✓ TechDocs (infrastructure documentation)                      │
│  ✓ Software templates (VM deployment automation)                │
│  ✓ Kubernetes plugin (if using k8s)                             │
│  ✓ Custom plugins for Proxmox management                        │
│                                                                  │
│  Security:                                                       │
│  - OAuth2/OIDC authentication                                    │
│  - RBAC via Backstage permissions                               │
│  - Only talks to Vapor API (never direct to Proxmox)            │
└──────────────────────────┬───────────────────────────────────────┘
                           ↓
                   [Internal Network]
                   No direct internet access
                           ↓
┌──────────────────────────────────────────────────────────────────┐
│  LAYER 2: Vapor API Middleware (VM 401) ← THE MAZE               │
│  ────────────────────────────────────────────────────────────────│
│  Technology: Swift + Vapor 4.x                                   │
│  Port: 8080 (firewalled, only accessible from Backstage VM)      │
│  IP: 192.168.100.41                                              │
│                                                                  │
│  Purpose: The "AI Maze" - Confuses automated scanners            │
│                                                                  │
│  Features:                                                       │
│  ✓ Swift-based REST API (uncommon = scanner confusion)          │
│  ✓ Custom request/response formats (not typical JSON REST)      │
│  ✓ Token-based authentication with custom schemes               │
│  ✓ Request obfuscation and fingerprint randomization            │
│  ✓ Honeypot endpoints (fake vulns to detect scanners)           │
│  ✓ Rate limiting per endpoint with exponential backoff          │
│  ✓ Proxmox API translation layer                                │
│                                                                  │
│  Maze Techniques:                                                │
│  - Non-standard HTTP headers (X-ORION-*, not X-Forwarded-*)     │
│  - Custom error messages (not Apache/nginx patterns)            │
│  - Response timing randomization                                │
│  - Fake technology signatures in headers                        │
│  - Honeypot routes that ban on access                           │
│                                                                  │
│  Security:                                                       │
│  - JWT validation (from Backstage)                              │
│  - IP whitelist (only Backstage VM)                             │
│  - Request signing/verification                                 │
│  - Audit logging of all API calls                               │
└──────────────────────────┬───────────────────────────────────────┘
                           ↓
                   [Management Network]
                   Completely isolated
                           ↓
┌──────────────────────────────────────────────────────────────────┐
│  LAYER 3: Proxmox VE (Hypervisor)                                │
│  ────────────────────────────────────────────────────────────────│
│  IP: 192.168.100.10:8006                                         │
│  Access: ONLY via Vapor API middleware                           │
│  Firewall: Port 8006 blocked from all except 192.168.100.41     │
│                                                                  │
│  Contains:                                                       │
│  - Router VM (200)                                               │
│  - AI Agent VM (300)                                             │
│  - macOS VM (100)                                                │
│  - Backstage VM (400) ← new                                      │
│  - Vapor API VM (401) ← new                                      │
└──────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Virtual Machine Specifications

### VM 400: Backstage Developer Portal

```json
{
  "id": 400,
  "name": "ORION-Backstage",
  "os": "Ubuntu 24.04 LTS",
  "description": "Spotify Backstage developer portal for infrastructure management",
  "resources": {
    "cpu": {
      "cores": 4,
      "type": "host"
    },
    "memory": "16GB",
    "storage": "100GB"
  },
  "network": [
    {
      "bridge": "vmbr1",
      "ip": "192.168.100.40/24",
      "gateway": "192.168.100.1"
    }
  ],
  "software": [
    "Node.js 20.x LTS",
    "Backstage v1.23+",
    "PostgreSQL 16 (for Backstage catalog)",
    "nginx (reverse proxy)",
    "Let's Encrypt SSL"
  ],
  "ports": {
    "internal": 7007,
    "external": 443
  },
  "autostart": true,
  "startupOrder": 5
}
```

### VM 401: Vapor API Middleware

```json
{
  "id": 401,
  "name": "ORION-VaporAPI",
  "os": "Ubuntu 24.04 LTS",
  "description": "Swift/Vapor API middleware - The AI Maze layer",
  "resources": {
    "cpu": {
      "cores": 4,
      "type": "host"
    },
    "memory": "8GB",
    "storage": "50GB"
  },
  "network": [
    {
      "bridge": "vmbr1",
      "ip": "192.168.100.41/24",
      "gateway": "192.168.100.1"
    }
  ],
  "software": [
    "Swift 5.10+",
    "Vapor 4.x",
    "Redis (caching/rate limiting)",
    "systemd (service management)"
  ],
  "ports": {
    "internal": 8080,
    "external": "none (firewalled)"
  },
  "firewall": {
    "allowFrom": ["192.168.100.40"],
    "denyAll": true
  },
  "autostart": true,
  "startupOrder": 4
}
```

---

## 🔒 Security Features: The "Maze" Techniques

### 1. **Technology Signature Confusion**

#### Standard Stack (What Scanners Expect):
```
User → nginx/Apache → PHP/Node.js/Python → MySQL/PostgreSQL
      (Known signatures)  (CVE databases)
```

#### AI Maze Stack (What We Deploy):
```
User → Backstage (Node) → Vapor (Swift) → Proxmox API
      (Legitimate)       (Uncommon)      (Protected)
```

**Why it works:**
- Swift backend rarely used for infrastructure tools
- Scanners have minimal Swift vulnerability signatures
- No common framework patterns (Laravel, Express, Django)
- Custom error messages don't match known fingerprints

### 2. **Honeypot Endpoints**

Fake vulnerable endpoints that detect and ban scanners:

```swift
// In Vapor API
app.get("wp-admin", "login.php", ".env", "config.php") { req -> Response in
    // Log attacker IP
    let ip = req.remoteAddress?.ipAddress ?? "unknown"
    logger.warning("Scanner detected from \(ip) - accessing honeypot")

    // Ban IP via nftables
    try await banIP(ip)

    // Return fake vulnerable response to waste scanner time
    return Response(
        status: .ok,
        body: .init(string: generateFakeVulnerableHTML())
    )
}
```

### 3. **Request Obfuscation**

Custom request/response formats that confuse AI parsers:

```swift
// Non-standard authentication
struct OrionAuthToken: Content {
    let token: String
    let timestamp: Int64
    let signature: String  // HMAC-SHA512
    let nonce: String      // Prevents replay
}

// Custom response wrapper
struct OrionResponse<T: Content>: Content {
    let data: T?
    let meta: ResponseMeta
    let _trace: String  // Random UUID per request
}
```

### 4. **Response Timing Randomization**

```swift
// Add random delay to prevent timing attacks and confuse automated tools
func randomDelay() async {
    let delay = UInt64.random(in: 50_000_000...150_000_000) // 50-150ms
    try? await Task.sleep(nanoseconds: delay)
}
```

### 5. **Fake Technology Headers**

```swift
// Make scanners think we're running different tech
let fakeHeaders = [
    "X-Powered-By": "ASP.NET", // We're not .NET
    "Server": "Microsoft-IIS/10.0", // We're not IIS
    "X-AspNet-Version": "4.0.30319"
]
```

---

## 📦 Deployment Process

### Step 1: Deploy Proxmox Base (Already Done)

Use existing `deploy-orion-hybrid.py` to set up:
- Proxmox VE
- Router VM
- AI Agent VM
- macOS VM (optional)

### Step 2: Create Vapor API VM

```bash
# On Proxmox host
qm create 401 \
  --name ORION-VaporAPI \
  --cores 4 \
  --memory 8192 \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:50 \
  --ostype l26

# Download Ubuntu 24.04 ISO
wget -O /var/lib/vz/template/iso/ubuntu-24.04-live-server-amd64.iso \
  https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso

# Mount and start
qm set 401 --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom
qm start 401
```

**Install Swift + Vapor:**
```bash
# SSH into VM 401
ssh root@192.168.100.41

# Install Swift
wget https://download.swift.org/swift-5.10-release/ubuntu2404/swift-5.10-RELEASE/swift-5.10-RELEASE-ubuntu24.04.tar.gz
tar xzf swift-5.10-RELEASE-ubuntu24.04.tar.gz
mv swift-5.10-RELEASE-ubuntu24.04 /opt/swift
echo 'export PATH=/opt/swift/usr/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Create Vapor project
mkdir -p /opt/orion-api
cd /opt/orion-api
vapor new . --template api
```

### Step 3: Create Backstage VM

```bash
# Create VM
qm create 400 \
  --name ORION-Backstage \
  --cores 4 \
  --memory 16384 \
  --net0 virtio,bridge=vmbr1 \
  --scsi0 local-lvm:100 \
  --ostype l26

qm set 400 --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom
qm start 400
```

**Install Backstage:**
```bash
# SSH into VM 400
ssh root@192.168.100.40

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Yarn
npm install -g yarn

# Create Backstage app
npx @backstage/create-app@latest --skip-install
cd backstage
yarn install
```

### Step 4: Configure Firewall Rules

```bash
# On Router VM (200) - using nftables
nft add rule inet filter input ip saddr 192.168.100.40 tcp dport 8080 ip daddr 192.168.100.41 accept comment "Backstage → Vapor"
nft add rule inet filter input tcp dport 8080 drop comment "Block direct Vapor access"
nft add rule inet filter input ip saddr 192.168.100.41 tcp dport 8006 ip daddr 192.168.100.10 accept comment "Vapor → Proxmox"
nft add rule inet filter input tcp dport 8006 drop comment "Block direct Proxmox access"
```

---

## 🔧 Sample Code: Vapor API Middleware

Create `/opt/orion-api/Sources/App/routes.swift`:

```swift
import Vapor
import Fluent

func routes(_ app: Application) throws {

    // Health check (public)
    app.get("health") { req async -> Response in
        await randomDelay()
        return Response(status: .ok, body: .init(string: "OK"))
    }

    // Honeypot routes
    let honeypots = ["wp-admin", "wp-login.php", ".env", "admin.php", "phpinfo.php"]
    for route in honeypots {
        app.get(route) { req async throws -> Response in
            try await handleHoneypot(req)
        }
    }

    // Protected API group
    let api = app.grouped("api", "v1")
    api.grouped(OrionAuthMiddleware()).group("proxmox") { proxmox in

        // List VMs
        proxmox.get("vms") { req async throws -> OrionResponse<[VMInfo]> in
            await randomDelay()
            let vms = try await ProxmoxClient.shared.listVMs()
            return OrionResponse(data: vms, meta: ResponseMeta())
        }

        // Create VM
        proxmox.post("vms") { req async throws -> OrionResponse<VMInfo> in
            await randomDelay()
            let input = try req.content.decode(CreateVMRequest.self)
            let vm = try await ProxmoxClient.shared.createVM(input)
            return OrionResponse(data: vm, meta: ResponseMeta())
        }

        // Start VM
        proxmox.post("vms", ":id", "start") { req async throws -> OrionResponse<String> in
            await randomDelay()
            guard let id = req.parameters.get("id", as: Int.self) else {
                throw Abort(.badRequest)
            }
            try await ProxmoxClient.shared.startVM(id)
            return OrionResponse(data: "started", meta: ResponseMeta())
        }
    }
}

// Custom middleware for authentication
struct OrionAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Verify JWT from Backstage
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing token")
        }

        // Validate token
        try await validateToken(token)

        // Add custom headers to confuse scanners
        var response = try await next.respond(to: request)
        response.headers.add(name: "X-Powered-By", value: "ASP.NET")
        response.headers.add(name: "Server", value: "Microsoft-IIS/10.0")
        response.headers.add(name: "X-ORION-Trace", value: UUID().uuidString)

        return response
    }
}

// Honeypot handler
func handleHoneypot(_ req: Request) async throws -> Response {
    let ip = req.remoteAddress?.ipAddress ?? "unknown"
    req.logger.warning("🍯 Honeypot triggered by \(ip) - \(req.url.path)")

    // Ban IP (integrate with router firewall)
    try await banIP(ip)

    // Return fake vulnerable response
    let fakeHTML = """
    <!DOCTYPE html>
    <html>
    <head><title>Admin Login</title></head>
    <body>
        <form action="/admin.php" method="post">
            <input type="text" name="user">
            <input type="password" name="pass">
            <input type="submit">
        </form>
    </body>
    </html>
    """

    return Response(
        status: .ok,
        headers: HTTPHeaders([
            ("Content-Type", "text/html"),
            ("X-Powered-By", "PHP/7.4.33")
        ]),
        body: .init(string: fakeHTML)
    )
}

// Random delay to confuse timing attacks
func randomDelay() async {
    let delay = UInt64.random(in: 50_000_000...150_000_000) // 50-150ms
    try? await Task.sleep(nanoseconds: delay)
}
```

---

## 🎨 Backstage Configuration

Create custom Proxmox plugin in Backstage:

**File: `packages/backend/src/plugins/proxmox.ts`**

```typescript
import { Router } from 'express';
import axios from 'axios';

const VAPOR_API_URL = 'http://192.168.100.41:8080/api/v1';
const API_TOKEN = process.env.VAPOR_API_TOKEN;

export default async function createPlugin(): Promise<Router> {
  const router = Router();

  // List VMs
  router.get('/vms', async (req, res) => {
    try {
      const response = await axios.get(`${VAPOR_API_URL}/proxmox/vms`, {
        headers: {
          'Authorization': `Bearer ${API_TOKEN}`,
          'X-ORION-Client': 'backstage'
        }
      });
      res.json(response.data);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  // Create VM
  router.post('/vms', async (req, res) => {
    try {
      const response = await axios.post(
        `${VAPOR_API_URL}/proxmox/vms`,
        req.body,
        {
          headers: {
            'Authorization': `Bearer ${API_TOKEN}`,
            'X-ORION-Client': 'backstage'
          }
        }
      );
      res.json(response.data);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });

  return router;
}
```

---

## 📊 Expected Results: The "Maze" in Action

### Scenario 1: Automated Scanner

```
Scanner: Nmap port scan → Finds port 7007 open
Scanner: Banner grab → Gets "nginx" (reverse proxy)
Scanner: Directory brute force → Triggers honeypot
Result: IP banned via nftables, scanner thinks it found WordPress
Actual: No useful information gained, scanner wasted time
```

### Scenario 2: AI/ML Reconnaissance

```
AI Tool: Analyze HTTP responses → No Laravel/Express patterns
AI Tool: Fingerprint stack → Swift headers (uncommon, limited training data)
AI Tool: Try common exploits → No matching vulnerabilities (wrong tech)
Result: AI model confused, gives up or provides wrong assessment
```

### Scenario 3: Legitimate User

```
User: Access Backstage UI → Beautiful, functional portal
User: Click "Deploy VM" → Backstage → Vapor → Proxmox (seamless)
User: View infrastructure → Real-time data, clear interface
Result: Excellent UX, no awareness of security maze underneath
```

---

## 🔍 Monitoring the Maze

### Metrics to Track

1. **Honeypot Triggers**: How many IPs hit fake endpoints
2. **Banned IPs**: Automated scanner detection rate
3. **Request Patterns**: Identify bot vs. human behavior
4. **Technology Fingerprinting Attempts**: Log unusual User-Agents

### Grafana Dashboard

Add to AI Agent VM (300):

```yaml
# Prometheus metrics from Vapor API
- job_name: 'vapor-api'
  static_configs:
    - targets: ['192.168.100.41:9090']
  metrics_path: '/metrics'
```

**Dashboard Panels:**
- Honeypot hits over time
- Banned IPs (geographic heatmap)
- Request latency (with randomization)
- Authentication failures
- Technology fingerprinting attempts

---

## ⚠️ Limitations & Honest Assessment

### What This Protects Against ✅

- ✅ Automated vulnerability scanners (Nmap, Nikto, etc.)
- ✅ AI-powered reconnaissance tools (limited Swift training)
- ✅ Script kiddies using common exploit tools
- ✅ Crawler bots looking for known vulnerabilities
- ✅ Mass scanning campaigns

### What This Does NOT Protect Against ❌

- ❌ Determined human attackers
- ❌ Zero-day exploits in Swift/Vapor/Backstage
- ❌ Social engineering
- ❌ Insider threats
- ❌ DDoS attacks (need separate mitigation)
- ❌ Advanced persistent threats (APTs)

### Security Through Obscurity Warning ⚠️

**This is NOT a replacement for:**
- Proper authentication/authorization
- Regular security updates
- Network segmentation
- Intrusion detection systems
- Security audits and penetration testing

**This IS a complement to** defense-in-depth strategy.

---

## 🚀 Deployment Checklist

- [ ] Deploy base Proxmox with existing ORION stack
- [ ] Create VM 401 (Vapor API)
- [ ] Install Swift + Vapor on VM 401
- [ ] Implement Vapor API with honeypots
- [ ] Create VM 400 (Backstage)
- [ ] Install and configure Backstage
- [ ] Create Proxmox plugin for Backstage
- [ ] Configure firewall rules (block direct Proxmox access)
- [ ] Set up monitoring and alerting
- [ ] Test honeypot endpoints
- [ ] Test legitimate user workflows
- [ ] Document for team

---

## 📚 Additional Resources

- **Backstage**: https://backstage.io/docs
- **Vapor**: https://docs.vapor.codes/
- **Swift Server**: https://www.swift.org/server/
- **Security Through Obscurity**: https://owasp.org/www-community/controls/Security_by_Obscurity

---

**Status**: Architecture documented, ready for implementation
**Next Steps**: Begin VM deployment and Vapor API development
