#!/usr/bin/env python3
"""
ORION Autonomous Network Agent
Monitors and manages network infrastructure with AI intelligence

Features:
- Real-time network monitoring via Prometheus metrics
- Autonomous issue detection and remediation
- BGP session health monitoring
- Bandwidth analysis and reporting
- Automated alert generation
- Self-healing capabilities
"""

import time
import requests
import json
import logging
import subprocess
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from enum import Enum

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('/var/log/orion-agent.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class AlertSeverity(Enum):
    """Alert severity levels"""
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


@dataclass
class NetworkMetrics:
    """Network metrics snapshot"""
    timestamp: datetime
    wan_bandwidth_mbps: float
    lan_bandwidth_mbps: float
    bgp_sessions_up: int
    bgp_sessions_total: int
    packet_loss_percent: float
    latency_ms: float
    active_connections: int
    cpu_usage_percent: float
    memory_usage_percent: float


@dataclass
class Alert:
    """Network alert"""
    severity: AlertSeverity
    title: str
    message: str
    timestamp: datetime
    resolved: bool = False


class PrometheusClient:
    """Client for querying Prometheus metrics"""

    def __init__(self, url: str = "http://localhost:9090"):
        self.url = url
        self.session = requests.Session()

    def query(self, query: str) -> Optional[Dict]:
        """Execute PromQL query"""
        try:
            response = self.session.get(
                f"{self.url}/api/v1/query",
                params={"query": query},
                timeout=10
            )
            response.raise_for_status()
            data = response.json()

            if data["status"] == "success":
                return data["data"]
            return None
        except Exception as e:
            logger.error(f"Prometheus query failed: {e}")
            return None

    def query_range(self, query: str, start: int, end: int, step: str = "15s") -> Optional[Dict]:
        """Execute PromQL range query"""
        try:
            response = self.session.get(
                f"{self.url}/api/v1/query_range",
                params={
                    "query": query,
                    "start": start,
                    "end": end,
                    "step": step
                },
                timeout=10
            )
            response.raise_for_status()
            data = response.json()

            if data["status"] == "success":
                return data["data"]
            return None
        except Exception as e:
            logger.error(f"Prometheus range query failed: {e}")
            return None


class NetworkMonitor:
    """Network monitoring and analysis"""

    def __init__(self, router_ip: str = "192.168.100.1"):
        self.router_ip = router_ip
        self.prometheus = PrometheusClient()
        self.alerts: List[Alert] = []

    def collect_metrics(self) -> NetworkMetrics:
        """Collect current network metrics"""
        logger.debug("Collecting network metrics...")

        # Query Prometheus for metrics
        wan_rx = self._query_metric('rate(node_network_receive_bytes_total{device="eth0"}[5m])') or 0
        lan_rx = self._query_metric('rate(node_network_receive_bytes_total{device="eth1"}[5m])') or 0
        cpu_usage = self._query_metric('100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)') or 0
        memory_usage = self._query_metric('(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100') or 0

        # Get BGP session status
        bgp_sessions = self._check_bgp_sessions()

        # Ping test for latency
        latency = self._measure_latency("8.8.8.8")

        metrics = NetworkMetrics(
            timestamp=datetime.now(),
            wan_bandwidth_mbps=wan_rx * 8 / 1_000_000,  # Convert to Mbps
            lan_bandwidth_mbps=lan_rx * 8 / 1_000_000,
            bgp_sessions_up=bgp_sessions.get("up", 0),
            bgp_sessions_total=bgp_sessions.get("total", 3),
            packet_loss_percent=0.0,  # TODO: implement
            latency_ms=latency,
            active_connections=self._count_active_connections(),
            cpu_usage_percent=cpu_usage,
            memory_usage_percent=memory_usage
        )

        logger.info(f"Metrics: WAN={metrics.wan_bandwidth_mbps:.2f}Mbps, "
                   f"BGP={metrics.bgp_sessions_up}/{metrics.bgp_sessions_total}, "
                   f"CPU={metrics.cpu_usage_percent:.1f}%, "
                   f"MEM={metrics.memory_usage_percent:.1f}%")

        return metrics

    def _query_metric(self, query: str) -> Optional[float]:
        """Query single metric value from Prometheus"""
        result = self.prometheus.query(query)
        if result and result.get("result"):
            try:
                return float(result["result"][0]["value"][1])
            except (IndexError, KeyError, ValueError):
                return None
        return None

    def _check_bgp_sessions(self) -> Dict[str, int]:
        """Check BGP session status via birdc"""
        try:
            result = subprocess.run(
                ["ssh", f"admin@{self.router_ip}", "birdc", "show", "protocols"],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                output = result.stdout
                lines = output.split("\n")

                total = 0
                up = 0

                for line in lines:
                    if "BGP" in line and "telus_gw" in line:
                        total += 1
                        if "Established" in line:
                            up += 1

                return {"total": total, "up": up}

        except Exception as e:
            logger.error(f"BGP check failed: {e}")

        return {"total": 3, "up": 0}

    def _measure_latency(self, host: str) -> float:
        """Measure ping latency to host"""
        try:
            result = subprocess.run(
                ["ping", "-c", "3", "-W", "2", host],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                # Parse avg latency from output
                for line in result.stdout.split("\n"):
                    if "avg" in line or "rtt" in line:
                        parts = line.split("/")
                        if len(parts) >= 5:
                            return float(parts[4])

        except Exception as e:
            logger.error(f"Latency measurement failed: {e}")

        return 0.0

    def _count_active_connections(self) -> int:
        """Count active network connections"""
        try:
            result = subprocess.run(
                ["ss", "-tan", "state", "established"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0:
                lines = result.stdout.split("\n")
                # Subtract header line
                return max(0, len(lines) - 2)

        except Exception as e:
            logger.error(f"Connection count failed: {e}")

        return 0

    def analyze_metrics(self, metrics: NetworkMetrics):
        """Analyze metrics and generate alerts"""

        # Check BGP sessions
        if metrics.bgp_sessions_up < metrics.bgp_sessions_total:
            self._create_alert(
                AlertSeverity.CRITICAL,
                "BGP Sessions Down",
                f"Only {metrics.bgp_sessions_up}/{metrics.bgp_sessions_total} BGP sessions are established"
            )

        # Check high CPU usage
        if metrics.cpu_usage_percent > 90:
            self._create_alert(
                AlertSeverity.WARNING,
                "High CPU Usage",
                f"CPU usage is {metrics.cpu_usage_percent:.1f}%"
            )

        # Check high memory usage
        if metrics.memory_usage_percent > 95:
            self._create_alert(
                AlertSeverity.CRITICAL,
                "Critical Memory Usage",
                f"Memory usage is {metrics.memory_usage_percent:.1f}%"
            )

        # Check high latency
        if metrics.latency_ms > 100:
            self._create_alert(
                AlertSeverity.WARNING,
                "High Latency",
                f"Network latency is {metrics.latency_ms:.1f}ms"
            )

    def _create_alert(self, severity: AlertSeverity, title: str, message: str):
        """Create new alert"""
        alert = Alert(
            severity=severity,
            title=title,
            message=message,
            timestamp=datetime.now()
        )

        # Check if similar alert already exists
        for existing in self.alerts:
            if existing.title == title and not existing.resolved:
                logger.debug(f"Alert already exists: {title}")
                return

        self.alerts.append(alert)
        logger.warning(f"[{severity.value.upper()}] {title}: {message}")

        # Send notification (TODO: implement email/webhook)
        self._send_notification(alert)

    def _send_notification(self, alert: Alert):
        """Send alert notification"""
        # TODO: Implement email/Slack/webhook notification
        logger.info(f"Notification sent for: {alert.title}")

    def auto_remediate(self, metrics: NetworkMetrics):
        """Attempt automatic remediation of issues"""

        # Restart BGP if all sessions are down
        if metrics.bgp_sessions_up == 0 and metrics.bgp_sessions_total > 0:
            logger.warning("All BGP sessions down, attempting restart...")
            self._restart_bgp()

    def _restart_bgp(self):
        """Restart BGP service"""
        try:
            logger.info("Restarting BIRD BGP service...")
            result = subprocess.run(
                ["ssh", f"admin@{self.router_ip}", "sudo", "systemctl", "restart", "bird2"],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode == 0:
                logger.info("BGP service restarted successfully")
                self._create_alert(
                    AlertSeverity.INFO,
                    "BGP Service Restarted",
                    "Automatically restarted BGP service due to all sessions being down"
                )
            else:
                logger.error(f"BGP restart failed: {result.stderr}")

        except Exception as e:
            logger.error(f"BGP restart failed: {e}")

    def generate_report(self, metrics: NetworkMetrics) -> str:
        """Generate network status report"""
        report = f"""
ORION Network Status Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

=== Network Performance ===
WAN Bandwidth: {metrics.wan_bandwidth_mbps:.2f} Mbps
LAN Bandwidth: {metrics.lan_bandwidth_mbps:.2f} Mbps
Latency: {metrics.latency_ms:.1f} ms
Packet Loss: {metrics.packet_loss_percent:.2f}%
Active Connections: {metrics.active_connections}

=== BGP Routing ===
Sessions Up: {metrics.bgp_sessions_up}/{metrics.bgp_sessions_total}
AS Number: 394955

=== System Resources ===
CPU Usage: {metrics.cpu_usage_percent:.1f}%
Memory Usage: {metrics.memory_usage_percent:.1f}%

=== Active Alerts ===
"""
        active_alerts = [a for a in self.alerts if not a.resolved]
        if active_alerts:
            for alert in active_alerts:
                report += f"[{alert.severity.value.upper()}] {alert.title}: {alert.message}\n"
        else:
            report += "No active alerts\n"

        return report


class ORIONAgent:
    """Main autonomous agent"""

    def __init__(self):
        self.monitor = NetworkMonitor()
        self.running = False
        self.check_interval = 60  # seconds

    def start(self):
        """Start the agent"""
        logger.info("ORION Autonomous Agent starting...")
        logger.info(f"Check interval: {self.check_interval}s")

        self.running = True

        try:
            while self.running:
                self._run_cycle()
                time.sleep(self.check_interval)

        except KeyboardInterrupt:
            logger.info("Agent stopped by user")
        except Exception as e:
            logger.error(f"Agent error: {e}")
            raise
        finally:
            self.stop()

    def stop(self):
        """Stop the agent"""
        logger.info("ORION Autonomous Agent stopping...")
        self.running = False

    def _run_cycle(self):
        """Run one monitoring cycle"""
        try:
            # Collect metrics
            metrics = self.monitor.collect_metrics()

            # Analyze for issues
            self.monitor.analyze_metrics(metrics)

            # Attempt auto-remediation
            self.monitor.auto_remediate(metrics)

            # Generate hourly report
            if datetime.now().minute == 0:
                report = self.monitor.generate_report(metrics)
                logger.info(report)

        except Exception as e:
            logger.error(f"Monitoring cycle failed: {e}")


def main():
    """Main entry point"""
    print("""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        ORION Autonomous Network Agent v1.0                ║
║                                                           ║
║  Intelligent monitoring and management for ORION system   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
""")

    agent = ORIONAgent()
    agent.start()


if __name__ == "__main__":
    main()
